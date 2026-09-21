import Foundation
import Observation

/// Kayıt ekranının durumu. Süre sınırları sunucudan gelir; uygulamada sabit sınır yoktur (rules.md §4).
@Observable
@MainActor
final class RecordingViewModel {
    nonisolated enum Phase: Sendable, Equatable {
        case idle
        case recording
        case paused
        case review
        case submitting
    }

    private(set) var phase: Phase = .idle
    private(set) var permissionDenied = false
    private(set) var transcriptionUnavailable = false
    var transcript = ""
    var error: AppError?

    let recorder = AudioRecorderService()
    let transcriber = SpeechTranscriberService()
    let player = AudioPlayerService()

    @ObservationIgnored private let limits: RemoteAppConfig.RecordingLimits?
    @ObservationIgnored private let language: AppLanguage
    @ObservationIgnored private var recordedAt = Date()

    init(limits: RemoteAppConfig.RecordingLimits?, language: AppLanguage) {
        self.limits = limits
        self.language = language
    }

    var duration: TimeInterval { recorder.duration }
    var level: Double { recorder.level }
    var minSeconds: Int { limits?.minSeconds ?? 0 }
    var maxSeconds: Int { limits?.maxSeconds ?? 0 }
    var transcriptLimit: Int? { limits?.maxTranscriptCharacters }
    var displayedTranscript: String {
        phase == .review || phase == .submitting ? transcript : transcriber.transcript
    }

    /// Sunucunun alt sınırına ulaşmadan kayıt gönderilemez; üst sınıra gelince kayıt durur.
    var canFinish: Bool { Int(duration) >= max(minSeconds, 1) }
    var remainingSeconds: Int? { maxSeconds > 0 ? max(0, maxSeconds - Int(duration)) : nil }

    func start() async {
        error = nil
        permissionDenied = false
        transcriptionUnavailable = false
        recordedAt = Date()
        transcript = ""
        do {
            if AudioPermissions.microphone != .granted {

                let status = await AudioPermissions.requestMicrophone()
                guard status == .granted else { throw AudioRecorderService.RecorderError.microphonePermissionDenied }
            }
            do {
                try await transcriber.start(language: language.rawValue)
            } catch {
                // Transkripsiyon yoksa ses dosyası endpoint'i kullanılabilir; kayıt engellenmez.
                transcriptionUnavailable = true
            }
            recorder.onBuffer = { [transcriber] buffer in transcriber.appendBuffer(buffer) }
            recorder.onInterruption = { [weak self] in
                self?.phase = .paused
            }
            try await recorder.start()
            phase = .recording
        } catch AudioRecorderService.RecorderError.microphonePermissionDenied {
            transcriber.stop()
            permissionDenied = true
        } catch {
            transcriber.stop()
            self.error = .unexpectedResponse(status: nil)
        }
    }

    func pause() {
        recorder.pause()
        phase = .paused
    }

    func resume() {
        do {
            try recorder.resume()
            phase = .recording
        } catch {
            self.error = .unexpectedResponse(status: nil)
        }
    }

    /// Kaydı bitirir ve inceleme ekranına geçer; ses dosyası gönderilene kadar cihazda kalır.
    func finish() {
        transcriber.stop()
        _ = recorder.stop()
        transcript = transcriber.transcript
        if let url = recorder.fileURL { try? player.load(url: url) }
        phase = .review
    }

    func discard() {
        transcriber.stop()
        recorder.discard()
        player.stop()
        phase = .idle
        transcript = ""
    }

    func releaseKeepingAudioFile() {
        transcriber.stop()
        recorder.releaseKeepingFile()
        player.stop()
        phase = .idle
    }

    func beginSubmitting() {
        guard phase == .review else { return }
        error = nil
        player.pause()
        phase = .submitting
    }

    func finishSubmitting(error: AppError?) {
        self.error = error
        phase = .review
    }

    /// Süre üst sınıra ulaştığında kayıt kendiliğinden biter; istemci sınırı kendisi belirlemez.
    func enforceLimit() {
        guard maxSeconds > 0, Int(duration) >= maxSeconds, phase == .recording else { return }
        finish()
    }

    var recordedDate: Date { recordedAt }
    var audioURL: URL? { recorder.fileURL }
    var audioDurationSeconds: Int { Int(recorder.duration.rounded()) }
}
