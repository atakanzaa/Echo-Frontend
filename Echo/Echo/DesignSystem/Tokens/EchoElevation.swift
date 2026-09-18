import SwiftUI

/// Yükseklik seviyeleri (implementation.md §3.6).
/// Light temada gölge; dark temada gölge yok, yüzey açıklığı ve ışıma kullanılır.
nonisolated enum EchoElevation: Int, CaseIterable, Comparable, Sendable {
    case level0
    case level1
    case level2
    case level3
    case level4

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Basılı kartlarda bir kademe düşük seviye.
    var lowered: EchoElevation { EchoElevation(rawValue: max(0, rawValue - 1)) ?? .level0 }

    var lightShadow: EchoShadow? {
        switch self {
        case .level0: nil
        case .level1: EchoShadow(y: 2, radius: 4, opacity: 0.06)
        case .level2: EchoShadow(y: 4, radius: 8, opacity: 0.08)
        case .level3: EchoShadow(y: 8, radius: 14, opacity: 0.10)
        case .level4: EchoShadow(y: 16, radius: 24, opacity: 0.14)
        }
    }

    var darkGlow: EchoShadow? {
        switch self {
        case .level0, .level1, .level2: nil
        case .level3: EchoShadow(y: 0, radius: 12, opacity: 0.08)
        case .level4: EchoShadow(y: 0, radius: 20, opacity: 0.14)
        }
    }

    var hasDarkBorder: Bool { self == .level1 }
    var usesRaisedSurfaceInDark: Bool { self >= .level2 }
}

nonisolated struct EchoShadow: Sendable {
    let y: CGFloat
    let radius: CGFloat
    let opacity: Double
}

private struct EchoSurfaceModifier<SurfaceShape: InsettableShape>: ViewModifier {
    let level: EchoElevation
    let shape: SurfaceShape
    let fill: Color?
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background {
            if colorScheme == .dark {
                darkSurface
            } else {
                lightSurface
            }
        }
    }

    @ViewBuilder private var lightSurface: some View {
        let base = shape.fill(fill ?? AppTheme.color.bg.surface)
        if let shadow = level.lightShadow {
            base.shadow(color: EchoPrimitive.neutral950.opacity(shadow.opacity), radius: shadow.radius, x: 0, y: shadow.y)
        } else {
            base
        }
    }

    @ViewBuilder private var darkSurface: some View {
        let surfaceColor = fill ?? (level.usesRaisedSurfaceInDark ? AppTheme.color.bg.surfaceRaised : AppTheme.color.bg.surface)
        let base = shape.fill(surfaceColor)
            .overlay {
                if level.hasDarkBorder {
                    shape.strokeBorder(AppTheme.color.border.subtle, lineWidth: 1)
                }
            }
        if let glow = level.darkGlow {
            base.shadow(color: EchoPrimitive.violet400.opacity(glow.opacity), radius: glow.radius)
        } else {
            base
        }
    }
}

extension View {
    /// Yüzeyi seviyeye göre boyar: light temada gölge, dark temada yüzey + kenar/ışıma. İçeriğe gölge düşmez.
    func echoSurface<SurfaceShape: InsettableShape>(_ level: EchoElevation, in shape: SurfaceShape, fill: Color? = nil) -> some View {
        modifier(EchoSurfaceModifier(level: level, shape: shape, fill: fill))
    }

    func echoSurface(_ level: EchoElevation, cornerRadius: CGFloat, fill: Color? = nil) -> some View {
        echoSurface(level, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), fill: fill)
    }
}
