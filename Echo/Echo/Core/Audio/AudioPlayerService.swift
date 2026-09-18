import AVFoundation
import Observation

/// Kayıttan hemen sonra dinleme için basit oynatıcı (implementation.md §5.5).
@Observable
@MainActor
final class AudioPlayerService {
    private(set) var isPlaying = false
    private(set) var progress: Double = 0
    private(set) var duration: TimeInterval = 0
    var rate: Float = 1.0 {
        didSet { player?.rate = isPlaying ? rate : 0 }
    }

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var timer: Timer?

    func load(url: URL) throws {
        stop()
        let player = try AVAudioPlayer(contentsOf: url)
        player.enableRate = true
        player.prepareToPlay()
        self.player = player
        duration = player.duration
        progress = 0
    }

    func play() {
        guard let player else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.rate = rate
        player.play()
        isPlaying = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                if !player.isPlaying && self.isPlaying {

                    self.isPlaying = false
                    self.timer?.invalidate()
                }
            }
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    /// 0–1 aralığında konum.
    func seek(to position: Double) {
        guard let player else { return }
        player.currentTime = player.duration * min(max(position, 0), 1)
        progress = min(max(position, 0), 1)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        duration = 0
    }
}
