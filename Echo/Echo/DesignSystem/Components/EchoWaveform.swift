import SwiftUI

/// Dalga formu (implementation.md §4.16). Tek component, üç mod.
nonisolated enum EchoWaveformMode: Sendable {
    /// Kayıt sırasında: son örnekler ortadan dışa doğru akar.
    case live(level: Float)
    /// Kart içindeki özet.
    case summary(samples: [Float])
    /// Oynatıcı: çalınan bölüm vurgulu, sürüklenerek konum değiştirilir.
    case player(samples: [Float], progress: Double)
}

struct EchoWaveform: View {
    let mode: EchoWaveformMode
    var height: CGFloat = 56
    var onScrub: ((Double) -> Void)?
    @State private var liveHistory: [Float] = []
    @State private var canvasWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let barWidth: CGFloat = 3
    private static let barGap: CGFloat = 2
    private static let minBarHeight: CGFloat = 4
    private static let liveBarCount = 40
    private static let summaryBarCount = 60

    var body: some View {
        Canvas { canvas, size in

            let bars = resolvedBars(width: size.width)
            guard !bars.isEmpty else { return }
            let step = Self.barWidth + Self.barGap
            let totalWidth = CGFloat(bars.count) * step - Self.barGap
            let startX = (size.width - totalWidth) / 2

            for (index, bar) in bars.enumerated() {

                let barHeight = max(Self.minBarHeight, CGFloat(bar.value) * size.height)
                let rect = CGRect(x: startX + CGFloat(index) * step,
                                  y: (size.height - barHeight) / 2,
                                  width: Self.barWidth,
                                  height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: Self.barWidth / 2)
                canvas.fill(path, with: .color(bar.isHighlighted ? highlightColor : baseColor))
            }
        }
        .frame(height: height)
        .background {
            GeometryReader { proxy in

                Color.clear
                    .onAppear { canvasWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, width in canvasWidth = width }
            }
        }
        .contentShape(Rectangle())
        .gesture(scrubGesture)
        .onChange(of: liveLevel) { _, newValue in

            guard let newValue else { return }
            appendLiveSample(newValue)
        }
        .accessibilityHidden(onScrub == nil)
    }

    private struct Bar {
        let value: Float
        let isHighlighted: Bool
    }

    private var liveLevel: Float? {
        if case let .live(level) = mode { return level }
        return nil
    }

    private var baseColor: Color {
        switch mode {
        case .live: AppTheme.color.accent.secondary
        case .summary: AppTheme.color.content.tertiary
        case .player: AppTheme.color.border.default
        }
    }

    private var highlightColor: Color { AppTheme.color.accent.secondary }

    private func appendLiveSample(_ level: Float) {
        var history = liveHistory
        history.append(min(max(level, 0), 1))
        if history.count > Self.liveBarCount { history.removeFirst(history.count - Self.liveBarCount) }
        liveHistory = history
    }

    private func resolvedBars(width: CGFloat) -> [Bar] {
        switch mode {
        case .live:
            // En yeni örnek ortada durur, eskiler iki yana doğru açılır.
            let newestFirst = Array(liveHistory.reversed())
            let half = (Self.liveBarCount + 1) / 2
            let side = (0..<half).map { index in

                index < newestFirst.count ? newestFirst[index] : 0
            }
            let mirrored = Array(side.reversed().dropLast()) + side
            return mirrored.map { Bar(value: $0, isHighlighted: false) }
        case .summary(let samples):
            return resample(samples, count: Self.summaryBarCount).map { Bar(value: $0, isHighlighted: false) }
        case .player(let samples, let progress):
            let count = max(1, Int((width + Self.barGap) / (Self.barWidth + Self.barGap)))
            let values = resample(samples, count: min(count, Self.summaryBarCount))
            let playedCount = Int((Double(values.count) * min(max(progress, 0), 1)).rounded())
            return values.enumerated().map { Bar(value: $1, isHighlighted: $0 < playedCount) }
        }
    }

    /// Örnekleri hedef çubuk sayısına indirger; veri yoksa sessiz çizgi kalır.
    private func resample(_ samples: [Float], count: Int) -> [Float] {
        guard !samples.isEmpty, count > 0 else { return Array(repeating: 0, count: max(count, 0)) }
        if samples.count == count { return samples }
        return (0..<count).map { index in

            let start = index * samples.count / count
            let end = max(start + 1, (index + 1) * samples.count / count)
            let slice = samples[start..<min(end, samples.count)]
            return slice.reduce(0, +) / Float(slice.count)
        }
    }

    /// Sürükleme 0–1 aralığında konum bildirir; saniye hesabı çağıran tarafta yapılır.
    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0).onChanged { value in

            guard let onScrub, canvasWidth > 0 else { return }
            let position = min(max(value.location.x / canvasWidth, 0), 1)
            onScrub(Double(position))
        }
    }
}

#Preview("Dalga formu") {
    let samples = (0..<80).map { Float(abs(sin(Double($0) / 6)) * 0.8 + 0.1) }

    return VStack(spacing: AppTheme.space.lg) {
        EchoWaveform(mode: .summary(samples: samples), height: 40)
        EchoWaveform(mode: .player(samples: samples, progress: 0.45), height: 56)
        EchoWaveform(mode: .live(level: 0.6), height: 72)
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
