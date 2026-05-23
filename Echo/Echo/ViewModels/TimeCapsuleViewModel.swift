import Foundation
import Combine
import AVFoundation

@MainActor
final class TimeCapsuleViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {

    @Published var capsules:      [APITimeCapsule] = []
    @Published var isLoading      = false
    @Published var errorMessage:  String?
    @Published var showCreateSheet = false

    // Recording state
    @Published var isRecording    = false
    @Published var recordingTime  = "0:00"
    @Published var isCreating     = false

    private var recorder:         AVAudioRecorder?
    private var timer:            Timer?
    private var elapsedSeconds    = 0
    private var audioFileURL:     URL?
    private let capsulesTask      = TaskGuard()

    // Create sheet form
    @Published var capsuleTitle   = ""
    @Published var unlockInDays   = 90

    // MARK: — Load

    func loadCapsules() {
        capsulesTask.run { [weak self] in
            await self?.performLoadCapsules()
        }
    }

    // MARK: — Recording

    func toggleRecording() {
        isRecording ? stopAndPrepare() : startRecording()
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Deactivate first to clear stale category from Google Sign-In's
            // ASWebAuthenticationSession (leaves session in .soloAmbient with no mic).
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            guard !session.currentRoute.inputs.isEmpty else {
                throw NSError(domain: "EchoRecording", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "No audio input available"])
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("capsule_\(Date().timeIntervalSince1970).m4a")
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
            startTimer()
        } catch {
            errorMessage = LocalizationManager.shared.t("capsule.error.microphone_unavailable")
        }
    }

    private func stopAndPrepare() {
        recorder?.stop()
        timer?.invalidate()
        isRecording = false
    }

    func createCapsule() {
        isCreating = true
        let unlockDate = Calendar.current.date(byAdding: .day, value: unlockInDays, to: Date()) ?? Date()
        let iso = DateFormatting.iso8601String(from: unlockDate)
        let body = CreateCapsuleBody(
            title:       capsuleTitle.isEmpty ? nil : capsuleTitle,
            contentText: nil,
            contentType: audioFileURL != nil ? .audio : .text,
            unlockAt:    iso
        )

        Task {
            do {
                let capsule: APITimeCapsule
                if let audioFileURL {
                    let audioData = try Data(contentsOf: audioFileURL)
                    guard !audioData.isEmpty else {
                        throw NetworkError.invalidResponse
                    }
                    capsule = try await APIClient.shared.uploadWithAutoRefresh(
                        .createCapsule(
                            audioData: audioData,
                            filename: audioFileURL.lastPathComponent,
                            body: body
                        )
                    )
                } else {
                    capsule = try await APIClient.shared.requestWithAutoRefresh(
                        .createCapsule(audioData: nil, filename: nil, body: body)
                    )
                }
                capsules.insert(capsule, at: 0)
                isCreating       = false
                showCreateSheet  = false
                capsuleTitle     = ""
                unlockInDays     = 90
                if let url = audioFileURL {
                    try? FileManager.default.removeItem(at: url)
                }
                audioFileURL     = nil
                recordingTime    = "0:00"
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isCreating   = false
            }
        }
    }

    // MARK: — Helpers

    var nextUnlockCountdown: String {
        guard let next = capsules.filter({ $0.capsuleStatus == .sealed })
            .compactMap({ DateFormatting.parseISO8601($0.unlockAt) })
            .sorted().first else { return LocalizationManager.shared.t("capsule.next_unlock_none") }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        if days > 0 {
            return String(format: LocalizationManager.shared.t("capsule.next_unlock_days_fmt"), days)
        }
        return LocalizationManager.shared.t("capsule.next_unlock_unlocked")
    }

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

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}

    func refresh() async {
        await capsulesTask.runAsync { [weak self] in
            await self?.performLoadCapsules()
        }
    }

    func cancelAll() {
        capsulesTask.cancel()
        timer?.invalidate()
        timer = nil
    }

    private func performLoadCapsules() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: APIPagedResponse<APITimeCapsule> = try await APIClient.shared.requestWithAutoRefresh(
                .getCapsules
            )
            guard !Task.isCancelled else { return }
            capsules = result.content
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }
}

extension APITimeCapsule {
    var isSealed: Bool { capsuleStatus == .sealed }

    var unlockDateFormatted: String {
        guard let d = DateFormatting.parseISO8601(unlockAt) else { return unlockAt }
        return DateFormatting.mediumDate(from: d)
    }

    var sealedDateShort: String {
        guard let d = DateFormatting.parseISO8601(sealedAt) else { return "" }
        return DateFormatting.shortMonthYear(from: d)
    }
}
