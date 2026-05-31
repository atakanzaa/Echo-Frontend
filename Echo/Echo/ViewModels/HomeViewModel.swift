import Foundation
import Combine
import AVFoundation
import OSLog

@MainActor
final class HomeViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {

    // MARK: — Published State
    @Published var isRecording          = false
    @Published var recordingTime        = "0:00"
    @Published var statusKey            = "voice.status.ready"
    @Published var statusFallback: String?
    @Published var transcript           = ""
    @Published var isUploading          = false
    @Published var isProcessing         = false   // transcribing / analyzing
    @Published var awaitingConfirmation = false   // recorded, waiting for Send/Discard
    @Published var errorMessage:        String?
    @Published var recentEntries:       [APIJournalEntry] = []
    @Published var currentStreak:       Int = 0
    @Published var onThisDayEntries:    [APIOnThisDayEntry] = []

    // Live date header
    var dateLabel: String { formatDateLabel(Date()) }
    var greetingLabel: String { greetingForHour(Calendar.current.component(.hour, from: Date())) }

    // MARK: — Private
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var elapsedSeconds = 0
    private var audioFileURL: URL?
    private var pollingTask: Task<Void, Never>?
    private let loadRecentTask = TaskGuard()

    // MARK: — Recent Entries

    func loadRecent(limit: Int = 5) {
        loadRecentTask.run { [weak self] in
            await self?.performLoadRecent(limit: limit)
        }
        Task { [weak self] in
            await self?.loadOnThisDay()
        }
    }

    private func loadOnThisDay() async {
        do {
            let response: APIOnThisDayResponse = try await APIClient.shared.requestWithAutoRefresh(.getOnThisDay)
            onThisDayEntries = response.entries
        } catch {
            // Non-critical — silently fail
        }
    }

    // MARK: — Recording

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        errorMessage = nil
        transcript   = ""
        let session  = AVAudioSession.sharedInstance()
        do {
            // Deactivate first to clear any stale category (e.g. .soloAmbient left over
            // from ASWebAuthenticationSession used by Google Sign-In). Without this,
            // setCategory is silently ignored on an already-active session and the
            // recorder captures near-silence.
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
            try session.setActive(true)
            guard !session.currentRoute.inputs.isEmpty else {
                throw NSError(domain: "EchoRecording", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "No audio input available"])
            }
            let inputRoute = session.currentRoute.inputs.map { $0.portType.rawValue }.joined(separator: ",")
            let outputRoute = session.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("echo_\(Date().timeIntervalSince1970).m4a")
            audioFileURL = url

            let settings: [String: Any] = [
                AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey:          44100,
                AVNumberOfChannelsKey:    1,
                AVEncoderBitRateKey:      64_000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            Log.record.info("Journal recording started routeIn=\(inputRoute) routeOut=\(outputRoute)")

            isRecording    = true
            elapsedSeconds = 0
            setStatus("voice.status.recording")
            startTimer()
        } catch {
            errorMessage = LocalizationManager.shared.t("home.error.microphone_access")
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
        isRecording   = false
        setStatus("voice.status.processing")
        // upload is initiated in the delegate once the file is fully written to disk
    }

    // MARK: — Upload

    private func uploadRecording() async {
        guard elapsedSeconds >= 3 else {
            errorMessage = LocalizationManager.shared.t("home.error.recording_too_short")
            setStatus("voice.status.ready")
            return
        }
        guard let url = audioFileURL,
              let data = try? Data(contentsOf: url),
              !data.isEmpty else {
            errorMessage = LocalizationManager.shared.t("home.error.read_audio_file")
            setStatus("voice.status.ready")
            return
        }

        let session = AVAudioSession.sharedInstance()
        let inputRoute = session.currentRoute.inputs.map { $0.portType.rawValue }.joined(separator: ",")
        let outputRoute = session.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")
        let bytesPerSecond = data.count / max(elapsedSeconds, 1)
        Log.record.info("Journal upload prepared filename=\(url.lastPathComponent) bytes=\(data.count) durationSeconds=\(self.elapsedSeconds) bytesPerSecond=\(bytesPerSecond) routeIn=\(inputRoute) routeOut=\(outputRoute)")

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
            // First successful journal is the canonical moment to ask for push
            // permission. The manager guards itself so repeat calls are no-ops.
            Task { @MainActor in
                await PushNotificationManager.shared.requestAuthorizationIfNeeded()
            }
        } catch {
            isUploading   = false
            setStatus("voice.status.ready")
            errorMessage  = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }

        // Clean up temp file
        try? FileManager.default.removeItem(at: url)
        audioFileURL = nil
    }

    // MARK: — Status Polling

    private func startPolling(entryId: String) {
        isProcessing  = true
        setStatus("voice.status.analyzing")
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
                        setStatus("voice.status.complete")
                        isProcessing  = false
                        return
                    case "failed":
                        errorMessage = status.errorMessage ?? LocalizationManager.shared.t("home.error.processing_failed")
                        setStatus("voice.status.failed")
                        isProcessing  = false
                        return
                    default:
                        let localizedStatus = EntryStatus(rawBackend: status.status).displayTitle
                        setStatus("voice.status.processing", fallback: localizedStatus + "…")
                    }
                } catch {
                    // polling sırasında hata → devam et
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sn
            }
            // Zaman aşımı
            if !Task.isCancelled {
                errorMessage = LocalizationManager.shared.t("home.error.analysis_timed_out")
                setStatus("voice.status.timeout")
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
        let loc = LocalizationManager.shared
        switch hour {
        case 5..<12:  return loc.t("home.greeting_morning")
        case 12..<17: return loc.t("home.greeting_afternoon")
        case 17..<21: return loc.t("home.greeting_evening")
        default:      return loc.t("home.greeting_night")
        }
    }

    private func setStatus(_ key: String, fallback: String? = nil) {
        statusKey = key
        statusFallback = fallback
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
        elapsedSeconds = 0
        recordingTime  = "0:00"
        setStatus("voice.status.ready")
    }

    // MARK: — AVAudioRecorderDelegate

    // Called after recorder.stop() flushes the file to disk
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                                     successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                self.awaitingConfirmation = true
                self.setStatus("voice.status.recording_ready")
            } else {
                self.errorMessage = LocalizationManager.shared.t("home.error.recording_failed")
                self.setStatus("voice.status.failed")
            }
        }
    }

    func refresh() async {
        await loadRecentTask.runAsync { [weak self] in
            await self?.performLoadRecent(limit: 5)
        }
    }

    func cancelAll() {
        loadRecentTask.cancel()
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func performLoadRecent(limit: Int) async {
        async let entriesTask: [APIJournalEntry] = APIClient.shared.requestWithAutoRefresh(
            .getRecentJournalEntries(limit: limit)
        )
        async let profileTask: APIUser = APIClient.shared.requestWithAutoRefresh(.me)

        do {
            recentEntries = try await entriesTask
        } catch {
            // recent entries could not be loaded; keep previous state
        }

        do {
            let profile = try await profileTask
            currentStreak = profile.currentStreak
        } catch {
            // profile could not be loaded; keep previous state
        }
    }
}
