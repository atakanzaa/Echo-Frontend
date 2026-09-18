import SwiftUI

/// Sesin yankısını arka plana taşıyan canlı zemin (implementation.md §2.2).
/// `immersive` karşılama ve kimlik ekranlarında, `soft` form ekranlarında kullanılır.
/// Reduce Motion açıkken hareket durur; kompozisyon aynı kalır.
struct EchoAuroraBackground: View {
    nonisolated enum Style: Sendable {
        case immersive
        case soft
    }

    var style: Style = .immersive
    var intensity: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in

            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate / 14
            Canvas { canvas, size in

                drawBase(in: &canvas, size: size)
                canvas.addFilter(.blur(radius: style == .immersive ? 70 : 90))
                for blob in blobs(time: time, size: size) {

                    canvas.fill(Path(ellipseIn: blob.rect),
                                with: .radialGradient(Gradient(colors: [blob.color, blob.color.opacity(0)]),
                                                      center: CGPoint(x: blob.rect.midX, y: blob.rect.midY),
                                                      startRadius: 0,
                                                      endRadius: blob.rect.width / 2))
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawBase(in canvas: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let colors: [Color] = switch style {
        case .immersive:
            colorScheme == .dark
                ? [EchoPrimitive.neutral1000, EchoPrimitive.violet950, EchoPrimitive.aqua900]
                : [EchoPrimitive.violet900, EchoPrimitive.violet800, EchoPrimitive.aqua800]
        case .soft:
            [AppTheme.color.bg.canvas, AppTheme.color.bg.canvas]
        }
        canvas.fill(Path(rect), with: .linearGradient(Gradient(colors: colors),
                                                      startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                                      endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
    }

    /// Üç ışık kütlesi farklı hızlarda sürüklenir; hareket yavaştır, dikkat dağıtmaz.
    private func blobs(time: Double, size: CGSize) -> [Blob] {
        let width = size.width
        let height = size.height
        let radius = max(width, height) * (style == .immersive ? 0.95 : 0.75)
        let alpha = (style == .immersive ? 0.55 : 0.28) * intensity
        let palette: [Color] = colorScheme == .dark
            ? [EchoPrimitive.violet500, EchoPrimitive.aqua500, EchoPrimitive.violet700]
            : (style == .immersive
               ? [EchoPrimitive.violet400, EchoPrimitive.aqua400, EchoPrimitive.violet600]
               : [EchoPrimitive.violet300, EchoPrimitive.aqua200, EchoPrimitive.violet200])
        let centers: [CGPoint] = [
            CGPoint(x: width * (0.20 + 0.10 * sin(time)), y: height * (0.18 + 0.06 * cos(time * 0.9))),
            CGPoint(x: width * (0.85 + 0.08 * cos(time * 0.7)), y: height * (0.30 + 0.08 * sin(time * 1.1))),
            CGPoint(x: width * (0.50 + 0.12 * sin(time * 0.5)), y: height * (0.86 + 0.05 * cos(time * 0.8)))
        ]
        return zip(centers, palette).map { center, color in

            Blob(rect: CGRect(x: center.x - radius / 2, y: center.y - radius / 2, width: radius, height: radius),
                 color: color.opacity(alpha))
        }
    }

    private struct Blob {
        let rect: CGRect
        let color: Color
    }
}

/// Karşılama ekranının nefes alan yankı işareti: halkalar sesin dalgası gibi genişler.
struct EchoBrandMark: View {
    var size: CGFloat = 200
    var tint: Color = .white
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in

            let phase = reduceMotion ? 0.35 : (context.date.timeIntervalSinceReferenceDate / 3.2).truncatingRemainder(dividingBy: 1)
            ZStack {
                ForEach(0..<4, id: \.self) { index in

                    let offset = (phase + Double(index) / 4).truncatingRemainder(dividingBy: 1)
                    Circle()
                        .strokeBorder(tint.opacity((1 - offset) * 0.5), lineWidth: 1.5)
                        .frame(width: size * (0.35 + offset * 0.65), height: size * (0.35 + offset * 0.65))
                }
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: size * 0.34, height: size * 0.34)
                    .overlay {
                        Circle().strokeBorder(tint.opacity(0.65), lineWidth: 1.5)
                    }
                Image(systemName: "waveform")
                    .font(.system(size: size * 0.14, weight: .light))
                    .foregroundStyle(tint.opacity(0.9))
            }
            .frame(width: size, height: size)
        }
        .accessibilityHidden(true)
    }
}

/// Aurora zemin üzerinde okunabilirlik veren cam yüzey.
struct EchoGlassSurface<Content: View>: View {
    var cornerRadius: CGFloat = AppTheme.radius.xl
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AppTheme.space.md)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    }
            }
    }
}

#Preview("Aurora") {
    ZStack {
        EchoAuroraBackground()
        VStack(spacing: AppTheme.space.lg) {
            EchoBrandMark()
            EchoGlassSurface {
                Text(verbatim: "Sesin, yankısıyla")
                    .echoTextStyle(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}
