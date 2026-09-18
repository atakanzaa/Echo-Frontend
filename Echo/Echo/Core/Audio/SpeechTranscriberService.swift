import AVFoundation
import Observation
import Speech

/// Cihaz içi konuşma tanıma. Metin cihazda üretilir; ses sunucuya gitmez (rules.md §4).
@Observable
@MainActor
final class SpeechTranscriberService {
    nonisolated enum TranscriberError: Error, Sendable {
        case permissionDenied
        case recognizerUnavailable
    }

    private(set) var transcript = ""
    private(set) var isRunning = false
    /// Cihaz içi tanıma kullanılamadığında kullanıcıya bilgi verilir; sessizce sunucuya düşülmez.
    private(set) var isOnDevice = true

    @ObservationIgnored private var recognizer: SFSpeechRecognizer?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?

    /// `language` uygulama dilidir (`tr` veya `en`); tanıyıcı yerel ayarı buradan gelir.
    func start(language: String) async throws {
        guard !isRunning else { return }
        if AudioPermissions.speechRecognition != .granted {

            let status = await AudioPermissions.requestSpeechRecognition()
            guard status == .granted else { throw TranscriberError.permissionDenied }
        }

        let locale = Locale(identifier: language == "tr" ? "tr-TR" : "en-US")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriberError.recognizerUnavailable
        }
        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        isOnDevice = recognizer.supportsOnDeviceRecognition
        self.request = request

        transcript = ""
        isRunning = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {

                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {

                    self.finish()
                }
            }
        }
    }

    /// Kaydedicinin tamponlarını tanıyıcıya bağlar.
    nonisolated func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        Task { @MainActor [weak self] in
            self?.request?.append(buffer)
        }
    }

    func stop() {
        request?.endAudio()
        finish()
    }

    /// Kullanıcı metni düzenleyebilir; düzenleme sunucuya olduğu gibi gider.
    func replaceTranscript(_ text: String) {
        transcript = text
    }

    private func finish() {
        task?.cancel()
        task = nil
        request = nil
        isRunning = false
    }
}
