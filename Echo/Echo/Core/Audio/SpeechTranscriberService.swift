import AVFoundation
import Observation
import Speech

/// Cihaz içi konuşma tanıma. Metin cihazda üretilir; ses sunucuya gitmez (rules.md §4).
/// iOS bir duraklamadan sonra yeni ifadeye geçince önceki metni sonuçtan düşürür; biten ifadeler burada biriktirilir.
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

    nonisolated private let input = RecognitionInput()
    @ObservationIgnored private var recognizer: SFSpeechRecognizer?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var committed = ""
    @ObservationIgnored private var utterance = ""
    /// Aynı görevde, tanıyıcının biten ifadeyi sonraki sonuçlarda tekrar gönderdiği önek.
    @ObservationIgnored private var committedPrefix = ""
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var taskStartedAt = Date.distantPast
    @ObservationIgnored private var quickRestarts = 0

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
        isOnDevice = recognizer.supportsOnDeviceRecognition

        committed = ""
        utterance = ""
        transcript = ""
        quickRestarts = 0
        isRunning = true
        beginTask()
    }

    /// Kaydedicinin tamponlarını tanıyıcıya bağlar.
    nonisolated func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        input.append(buffer)
    }

    func stop() {
        guard isRunning else { return }
        commitUtterance()
        publish()
        isRunning = false
        input.end()
        task?.cancel()
        task = nil
        recognizer = nil
    }

    /// Kullanıcı metni düzenleyebilir; düzenleme sunucuya olduğu gibi gider.
    func replaceTranscript(_ text: String) {
        committed = text
        utterance = ""
        transcript = text
    }

    private func beginTask() {
        guard let recognizer else { return }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request.addsPunctuation = true
        input.replace(with: request)

        generation += 1
        let current = generation
        utterance = ""
        committedPrefix = ""
        taskStartedAt = Date()
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let endsUtterance = result.map { $0.isFinal || $0.speechRecognitionMetadata != nil } ?? false
            let ended = error != nil || (result?.isFinal ?? false)
            Task { @MainActor [weak self] in

                self?.receive(text: text, endsUtterance: endsUtterance, ended: ended, generation: current)
            }
        }
    }

    private func receive(text: String?, endsUtterance: Bool, ended: Bool, generation: Int) {
        guard isRunning, generation == self.generation else { return }
        if let text {

            var next = text
            if !committedPrefix.isEmpty {

                // Noktalama sonradan değişebildiği için önek kelime kelime karşılaştırılır.
                let prefixWords = Self.words(committedPrefix)
                if Self.words(next).starts(with: prefixWords) {

                    next = next.split(separator: " ").dropFirst(prefixWords.count).joined(separator: " ")
                } else {
                    committedPrefix = ""
                }
            }
            if Self.startsNewUtterance(previous: utterance, next: next) { commitUtterance() }
            utterance = next
            if endsUtterance {

                commitUtterance()
                committedPrefix = text
            }
            publish()
        }
        if ended {

            commitUtterance()
            publish()
            restartTask()
        }
    }

    /// Kayıt sürerken tanıma görevi biterse (süre sınırı, sessizlik hatası) yenisi açılır; peş peşe hızlı hatalarda durur.
    private func restartTask() {
        task?.cancel()
        task = nil
        input.end()
        quickRestarts = Date().timeIntervalSince(taskStartedAt) < 2 ? quickRestarts + 1 : 0
        guard quickRestarts < 5 else {

            isRunning = false
            return
        }
        beginTask()
    }

    private func commitUtterance() {
        let text = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        utterance = ""
        guard !text.isEmpty else { return }
        committed = committed.isEmpty ? text : committed + " " + text
    }

    private func publish() {
        transcript = [committed, utterance].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Bitiş işareti gelmeden sonuç sıfırlandıysa: uzun bir ifadenin yerine başka kelimeyle başlayan çok daha kısa bir metin gelir.
    private static func startsNewUtterance(previous: String, next: String) -> Bool {
        let previousWords = previous.split(separator: " ")
        guard previousWords.count >= 3, !next.isEmpty, next.count * 2 < previous.count else { return false }
        return firstWord(previous) != firstWord(next)
    }

    private static func firstWord(_ text: String) -> String {
        words(text).first ?? ""
    }

    private static func words(_ text: String) -> [String] {
        text.split(separator: " ").map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
    }
}

/// Ses tamponları kayıt iş parçacığından gelir; istek, görev yenilenirken kilit altında değiştirilir.
private final class RecognitionInput: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?

    func replace(with request: SFSpeechAudioBufferRecognitionRequest) {
        lock.withLock { self.request = request }
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.withLock { request?.append(buffer) }
    }

    func end() {
        lock.withLock {

            request?.endAudio()
            request = nil
        }
    }
}
