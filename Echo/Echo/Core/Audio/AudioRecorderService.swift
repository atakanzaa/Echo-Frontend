import AVFoundation
import Observation

/// Cihaz içi kayıt. Ses dosyası yalnız kullanıcı gönderene kadar cihazda durur.
/// Süre sınırları sunucudan gelir (`app/config.recording`); burada sabit sınır yoktur.
@Observable
@MainActor
final class AudioRecorderService {
    nonisolated enum RecorderError: Error, Sendable {
        case microphonePermissionDenied
        case engineUnavailable
        case fileUnavailable
    }

    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var duration: TimeInterval = 0
    /// 0–1 aralığında anlık seviye; yalnız dalga formu ve ripple için.
    private(set) var level: Double = 0
    private(set) var fileURL: URL?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var file: AVAudioFile?
    @ObservationIgnored private var converter: AVAudioConverter?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var timer: Timer?
    /// Canlı transkripsiyon aynı ses tamponlarını dinler.
    @ObservationIgnored var onBuffer: (@Sendable (AVAudioPCMBuffer) -> Void)?

    func start() async throws {
        guard !isRecording else { return }
        if AudioPermissions.microphone != .granted {

            let status = await AudioPermissions.requestMicrophone()
            guard status == .granted else { throw RecorderError.microphonePermissionDenied }
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: [])

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        let url = Self.newFileURL()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let file = try AVAudioFile(forWriting: url, settings: settings)
        self.file = file
        fileURL = url

        // Girişin cihaz biçimi dosyanın işleme biçiminden farklı olabilir; tamponlar dönüştürülerek yazılır.
        let processingFormat = file.processingFormat
        let converter = AVAudioConverter(from: inputFormat, to: processingFormat)
        self.converter = converter
        let onBuffer = self.onBuffer

        input.installTap(onBus: 0, bufferSize: 2_048, format: inputFormat) { [weak self] buffer, _ in
            // Yazma ve transkripsiyon ses iş parçacığında kalır; arayüze yalnız seviye taşınır.
            if let converted = Self.convert(buffer, using: converter, to: processingFormat) {

                try? file.write(from: converted)
            }
            onBuffer?(buffer)
            let peak = Self.meanSquareLevel(buffer)
            Task { @MainActor [weak self] in
                self?.level = peak
            }
        }

        engine.prepare()
        try engine.start()
        accumulated = 0
        startedAt = Date()
        isRecording = true
        isPaused = false
        startTicking()
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        engine.pause()
        accumulated += Date().timeIntervalSince(startedAt ?? Date())
        startedAt = nil
        isPaused = true
        timer?.invalidate()
    }

    func resume() throws {
        guard isRecording, isPaused else { return }
        try engine.start()
        startedAt = Date()
        isPaused = false
        startTicking()
    }

    /// Kaydı bitirir ve dosya adresini döndürür. Dosya gönderilene kadar silinmez.
    @discardableResult
    func stop() -> URL? {
        guard isRecording else { return fileURL }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        timer?.invalidate()
        timer = nil
        if let startedAt { accumulated += Date().timeIntervalSince(startedAt) }
        duration = accumulated
        startedAt = nil
        isRecording = false
        isPaused = false
        level = 0
        file = nil
        converter = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return fileURL
    }

    /// Gönderilmeyen kaydı siler.
    func discard() {
        _ = stop()
        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
        fileURL = nil
        duration = 0
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                self.duration = self.accumulated + Date().timeIntervalSince(startedAt)
            }
        }
    }

    private nonisolated static func convert(_ buffer: AVAudioPCMBuffer,
                                            using converter: AVAudioConverter?,
                                            to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter else { return buffer.format == format ? buffer : nil }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1_024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {

                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil ? output : nil
    }

    /// RMS tabanlı seviye; dB aralığı 0–1'e sıkıştırılır.
    private nonisolated static func meanSquareLevel(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }
        var sum: Float = 0
        for index in 0..<frames { sum += channel[index] * channel[index] }
        let rms = sqrt(sum / Float(frames))
        let decibels = 20 * log10(max(rms, 0.000_001))
        return Double(min(max((decibels + 50) / 50, 0), 1))
    }

    private static func newFileURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(UUID().uuidString).m4a")
    }
}
