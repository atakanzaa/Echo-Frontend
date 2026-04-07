import Foundation
import Combine
import AVFoundation

@MainActor
final class HomeViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {

    // MARK: — Published State
    @Published var isRecording         = false
    @Published var recordingTime       = "0:00"
    @Published var statusMessage       = "Ready to listen"
    @Published var transcript          = ""
    @Published var isUploading         = false
    @Published var isProcessing        = false   // transcribing / analyzing
    @Published var awaitingConfirmation = false  // recorded, waiting for Send/Discard
    @Published var errorMessage: String?

    // Live date header
    var dateLabel: String { formatDateLabel(Date()) }
    var greetingLabel: String { greetingForHour(Calendar.current.component(.hour, from: Date())) }

    // MARK: — Private
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var elapsedSeconds = 0
    private var audioFileURL: URL?
    private var pollingTask: Task<Void, Never>?

    deinit {
        timer?.invalidate()
        pollingTask?.cancel()
        recorder?.stop()
    }

    // MARK: — Recording

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task { await startRecording() }
        }
    }

    private func startRecording() async {
        errorMessage = nil
        transcript   = ""
        statusMessage = "Ready to listen"

        let permission = await MicrophonePermission.requestAccess()
        guard permission == .granted else {
            errorMessage = permission.errorMessage
            statusMessage = "Microphone permission required"
            return
        }

        beginRecording()
    }

    private func beginRecording() {
        let session  = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("echo_\(Date().timeIntervalSince1970).m4a")
            audioFileURL = url

            let settings: [String: Any] = [
                AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey:          44100,
                AVNumberOfChannelsKey:    1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()

            isRecording    = true
            elapsedSeconds = 0
            statusMessage  = "Recording…"
            Log.record.info("Started journal recording")
            startTimer()
        } catch {
            errorMessage = "Microphone access error: \(error.localizedDescription)"
            Log.record.error("Unable to start journal recording")
        }
    }

    func stopRecording() {
        // Capture actual duration before stop() resets currentTime
        let actual = Int(recorder?.currentTime ?? 0)
        elapsedSeconds = max(elapsedSeconds, actual)
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        recordingTime = String(format: "%d:%02d", m, s)

        recorder?.stop()   // triggers audioRecorderDidFinishRecording when file is flushed
        timer?.invalidate()
        timer = nil
        isRecording   = false
        statusMessage = "Processing…"
        Log.record.info("Stopped journal recording")
        // upload is initiated in the delegate once the file is fully written to disk
    }

    // MARK: — Upload

    private func uploadRecording() async {
        guard elapsedSeconds >= AppConstants.Recording.minimumDurationSeconds else {
            errorMessage  = "Recording too short. Please record at least \(AppConstants.Recording.minimumDurationSeconds) seconds."
            statusMessage = "Ready to listen"
            return
        }
        guard let url = audioFileURL,
              let data = try? Data(contentsOf: url),
              !data.isEmpty else {
            errorMessage  = "Could not read audio file."
            statusMessage = "Ready to listen"
            return
        }

        isUploading = true
        let isoNow  = DateFormatting.iso8601String(from: Date())

        do {
            let entry: APIJournalEntry = try await APIClient.shared.uploadWithAutoRefresh(
                .uploadJournalEntry(
                    audioData:       data,
                    filename:        url.lastPathComponent,
                    recordedAt:      isoNow,
                    durationSeconds: elapsedSeconds
                )
            )
            isUploading = false
            Log.record.info("Journal upload completed")
            startPolling(entryId: entry.id)
        } catch {
            isUploading   = false
            statusMessage = "Ready to listen"
            errorMessage  = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            Log.record.error("Journal upload failed")
        }

        // Clean up temp file
        try? FileManager.default.removeItem(at: url)
        audioFileURL = nil
    }

    // MARK: — Status Polling

    private func startPolling(entryId: String) {
        isProcessing  = true
        statusMessage = "Analyzing…"
        pollingTask?.cancel()
        pollingTask = Task {
            var attemptCount = 0
            let maxAttempts  = AppConstants.Polling.journalStatusMaxAttempts
            while !Task.isCancelled && attemptCount < maxAttempts {
                attemptCount += 1
                do {
                    let status: APIEntryStatus = try await APIClient.shared.requestWithAutoRefresh(
                        .getJournalEntryStatus(id: entryId)
                    )
                    switch status.entryStatus {
                    case .complete:
                        let entry: APIJournalEntry = try await APIClient.shared.requestWithAutoRefresh(
                            .getJournalEntry(id: entryId)
                        )
                        transcript    = entry.transcript ?? ""
                        statusMessage = "Analysis complete ✓"
                        isProcessing  = false
                        return
                    case .failed:
                        errorMessage  = status.errorMessage ?? "Processing failed."
                        statusMessage = "Ready to listen"
                        isProcessing  = false
                        return
                    default:
                        statusMessage = status.entryStatus.displayTitle + "…"
                    }
                } catch {
                    // polling sırasında hata → devam et
                }
                try? await Task.sleep(nanoseconds: AppConstants.Polling.journalStatusDelayNanoseconds)
            }
            // Zaman aşımı
            if !Task.isCancelled {
                errorMessage  = "Analysis timed out. Please try again later."
                statusMessage = "Ready to listen"
                isProcessing  = false
                Log.record.warning("Journal processing timed out")
            }
        }
    }

    // MARK: — Helpers

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.elapsedSeconds += 1
                let m = self.elapsedSeconds / 60
                let s = self.elapsedSeconds % 60
                self.recordingTime = String(format: "%d:%02d", m, s)
            }
        }
    }

    private func formatDateLabel(_ date: Date) -> String {
        DateFormatting.weekdayMonthDayUppercased(from: date)
    }

    private func greetingForHour(_ hour: Int) -> String {
        switch hour {
        case 5..<12:  return "Morning Reflection"
        case 12..<17: return "Afternoon Thoughts"
        case 17..<21: return "Evening Reflection"
        default:      return "Night Journal"
        }
    }

    // MARK: — Confirmation Actions

    func confirmUpload() {
        awaitingConfirmation = false
        Task { await uploadRecording() }
    }

    func discardRecording() {
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
            audioFileURL = nil
        }
        awaitingConfirmation = false
        pollingTask?.cancel()
        elapsedSeconds = 0
        recordingTime  = "0:00"
        statusMessage  = "Ready to listen"
    }

    // MARK: — AVAudioRecorderDelegate

    // Called after recorder.stop() flushes the file to disk
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                                     successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                self.awaitingConfirmation = true
                self.statusMessage = "Kayıt hazır"
            } else {
                self.errorMessage  = "Recording failed. Please try again."
                self.statusMessage = "Ready to listen"
            }
        }
    }
}
