import SwiftUI

/// Echo motifi: merkezden dışa açılan eş merkezli halkalar (implementation.md §2.2, §4.16).
/// Reduce Motion açıkken halkalar donar; hareket yerine sabit bir işaret kalır.
struct EchoRippleView: View {
    var ringCount: Int = 3
    /// Ses seviyesi veya yoğunluk (0–1). Halkaların opaklığını ve yayılma payını belirler.
    var intensity: Double = 0.5
    var speed: Double = 1.0
    var color: Color = AppTheme.color.accent.primary
    var isAnimating: Bool = true
    var lineWidth: CGFloat = 1.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedIntensity: Double { min(max(intensity, 0), 1) }
    private var isStatic: Bool { reduceMotion || !isAnimating }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isStatic)) { context in

            Canvas { canvas, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let minSide = min(size.width, size.height)
                let baseRadius = minSide * 0.22
                let travel = minSide * (0.24 + 0.14 * clampedIntensity)
                let cycle = AppTheme.motion.duration.ambient / max(speed, 0.1)
                let time = context.date.timeIntervalSinceReferenceDate / cycle

                for ring in 0..<max(ringCount, 1) {

                    let offset = Double(ring) / Double(max(ringCount, 1))
                    let phase = isStatic ? offset : (time + offset).truncatingRemainder(dividingBy: 1)
                    let radius = baseRadius + travel * phase
                    let fade = isStatic ? (1 - offset) : (1 - phase)
                    let opacity = fade * (0.18 + 0.52 * clampedIntensity)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    canvas.stroke(Path(ellipseIn: rect), with: .color(color.opacity(opacity)), lineWidth: lineWidth)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Koç yanıtı beklenirken gösterilen nabız (implementation.md §4.20). Üç nokta yerine üç halka.
struct EchoTypingIndicator: View {
    var color: Color = AppTheme.color.content.accent

    var body: some View {
        EchoRippleView(ringCount: 3, intensity: 0.35, speed: 0.6, color: color, lineWidth: 2)
            .frame(width: 44, height: 24)
            .accessibilityHidden(false)
            .accessibilityLabel(Text("coach.thinking"))
    }
}

#Preview("Ripple") {
    VStack(spacing: AppTheme.space.xl) {
        EchoRippleView(intensity: 0.8).frame(width: 180, height: 180)
        EchoTypingIndicator()
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
