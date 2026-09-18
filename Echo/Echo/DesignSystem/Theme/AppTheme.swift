import SwiftUI

/// Tasarım token'larına tek giriş noktası: `AppTheme.color.bg.surface`, `AppTheme.type.entry`, `AppTheme.space.md`.
/// Uygulamada bu facade dışında renk, font, boşluk veya köşe değeri yazılmaz.
nonisolated enum AppTheme {
    static let color = EchoColorPalette()
    static let gradient = EchoGradients()
    static let type = EchoTypeScale()
    static let space = EchoSpacingScale()
    static let layout = EchoLayoutMetrics()
    static let radius = EchoRadiusScale()
    static let icon = EchoIconScale()
    static let motion = EchoMotionTokens()
}
