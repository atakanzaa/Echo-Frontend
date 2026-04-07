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

    // Create sheet form
    @Published var capsuleTitle   = ""
    @Published var unlockInDays   = 90

    deinit {
        timer?.invalidate()
        recorder?.stop()
    }

    // MARK: — Load

    func loadCapsules() {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let result: [APITimeCapsule] = try await APIClient.shared.requestWithAutoRefresh(
                    .getCapsules
                )
                capsules  = result
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    // MARK: — Recording

    func toggleRecording() {
        if isRecording {
            stopAndPrepare()
        } else {
            Task { await startRecording() }
        }
    }

    private func startRecording() async {
        errorMessage = nil

        let permission = await MicrophonePermission.requestAccess()
        guard permission == .granted else {
            errorMessage = permission.errorMessage
            return
        }

        beginRecording()
    }

    private func beginRecording() {
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
        timer = nil
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
                var audioData: Data? = nil
                var filename:  String? = nil
                let fileURLToDelete = audioFileURL
                if let url = audioFileURL {
                    audioData = try? Data(contentsOf: url)
                    filename  = url.lastPathComponent
                }
                let capsule: APITimeCapsule = try await APIClient.shared.uploadWithAutoRefresh(
                    .createCapsule(audioData: audioData, filename: filename, body: body)
                )
                capsules.insert(capsule, at: 0)
                isCreating       = false
                showCreateSheet  = false
                capsuleTitle     = ""
                unlockInDays     = 90
                isRecording      = false
                audioFileURL     = nil
                recordingTime    = "0:00"
                if let url = fileURLToDelete { try? FileManager.default.removeItem(at: url) }
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
            .sorted().first else { return "No sealed capsules" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        return days > 0 ? "\(days) Days" : "Unlocked!"
    }

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

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}

extension APITimeCapsule {
    var isSealed: Bool { capsuleStatus == .sealed }

    var unlockDateFormatted: String {
        guard let date = DateFormatting.parseISO8601(unlockAt) else { return unlockAt }
        return DateFormatting.mediumDate(from: date)
    }

    var sealedDateShort: String {
        guard let date = DateFormatting.parseISO8601(sealedAt) else { return "" }
        return DateFormatting.shortMonthYear(from: date)
    }
}
