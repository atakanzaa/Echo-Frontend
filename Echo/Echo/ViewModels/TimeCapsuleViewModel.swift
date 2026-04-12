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
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
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
            errorMessage = "Mikrofona erişilemiyor."
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
        let iso = ISO8601DateFormatter().string(from: unlockDate)
        let body = CreateCapsuleBody(
            title:       capsuleTitle.isEmpty ? nil : capsuleTitle,
            contentText: nil,
            contentType: audioFileURL != nil ? .audio : .text,
            unlockAt:    iso
        )

        Task {
            do {
                let capsule: APITimeCapsule = try await APIClient.shared.requestWithAutoRefresh(
                    .createCapsule(audioData: nil, filename: nil, body: body)
                )
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
        guard let next = capsules.filter({ $0.status == "sealed" })
            .compactMap({ ISO8601DateFormatter().date(from: $0.unlockAt) })
            .sorted().first else { return "No sealed capsules" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        return days > 0 ? "\(days) Days" : "Unlocked!"
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
    var isSealed: Bool { status == "sealed" }

    var unlockDateFormatted: String {
        guard let d = ISO8601DateFormatter().date(from: unlockAt) else { return unlockAt }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: d)
    }

    var sealedDateShort: String {
        guard let d = ISO8601DateFormatter().date(from: sealedAt) else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"
        return f.string(from: d)
    }
}
