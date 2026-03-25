import Foundation
import Combine
import AVFoundation

@MainActor
final class HomeViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {

    // MARK: — Published State
    @Published var isRecording      = false
    @Published var recordingTime    = "0:00"
    @Published var statusMessage    = "Ready to listen"
    @Published var transcript       = ""
    @Published var isUploading      = false
    @Published var isProcessing     = false   // transcribing / analyzing
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

    // MARK: — Recording

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        errorMessage = nil
        transcript   = ""
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
            startTimer()
        } catch {
            errorMessage = "Microphone access error: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        recorder?.stop()   // triggers audioRecorderDidFinishRecording when file is flushed
        timer?.invalidate()
        isRecording   = false
        statusMessage = "Processing…"
        // upload is initiated in the delegate once the file is fully written to disk
    }

    // MARK: — Upload

    private func uploadRecording() async {
        guard let url = audioFileURL,
              let data = try? Data(contentsOf: url) else {
            errorMessage  = "Could not read audio file."
            statusMessage = "Ready to listen"
            return
        }

        isUploading = true
        let isoNow  = ISO8601DateFormatter().string(from: Date())

        do {
            let entry: APIJournalEntry = try await APIClient.shared.upload(
                .uploadJournalEntry(
                    audioData:       data,
                    filename:        url.lastPathComponent,
                    recordedAt:      isoNow,
                    durationSeconds: elapsedSeconds
                )
            )
            isUploading = false
            startPolling(entryId: entry.id)
        } catch {
            isUploading   = false
            statusMessage = "Ready to listen"
            errorMessage  = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
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
            let maxAttempts  = 30  // 30 × 2s = 60s max wait
            while !Task.isCancelled && attemptCount < maxAttempts {
                attemptCount += 1
                do {
                    let status: APIEntryStatus = try await APIClient.shared.requestWithAutoRefresh(
                        .getJournalEntryStatus(id: entryId)
                    )
                    switch status.status {
                    case "complete":
                        let entry: APIJournalEntry = try await APIClient.shared.requestWithAutoRefresh(
                            .getJournalEntry(id: entryId)
                        )
                        transcript    = entry.transcript ?? ""
                        statusMessage = "Analysis complete ✓"
                        isProcessing  = false
                        return
                    case "failed":
                        errorMessage  = status.errorMessage ?? "Processing failed."
                        statusMessage = "Ready to listen"
                        isProcessing  = false
                        return
                    default:
                        statusMessage = status.status.capitalized + "…"
                    }
                } catch {
                    // polling sırasında hata → devam et
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sn
            }
            // Zaman aşımı
            if !Task.isCancelled {
                errorMessage  = "Analysis timed out. Please try again later."
                statusMessage = "Ready to listen"
                isProcessing  = false
            }
        }
    }

    // MARK: — Helpers

    private func startTimer() {
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
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date).uppercased()
    }

    private func greetingForHour(_ hour: Int) -> String {
        switch hour {
        case 5..<12:  return "Morning Reflection"
        case 12..<17: return "Afternoon Thoughts"
        case 17..<21: return "Evening Reflection"
        default:      return "Night Journal"
        }
    }

    // MARK: — AVAudioRecorderDelegate

    // Called after recorder.stop() flushes the file to disk — safe to upload here
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                                     successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                await self.uploadRecording()
            } else {
                self.errorMessage  = "Recording failed. Please try again."
                self.statusMessage = "Ready to listen"
            }
        }
    }
}
