import SwiftUI

/// Kart container'ı (implementation.md §4.4).
nonisolated enum EchoCardStyle: Sendable, Equatable {
    case standard
    case flat
    case raised
    /// Yalnız paywall ve kutlama yüzeylerinde; içerik `content.onAccent` ile yazılır.
    case gradient
}

struct EchoCard<Content: View>: View {
    private let style: EchoCardStyle
    private let padding: CGFloat
    private let content: Content
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(style: EchoCardStyle = .standard, padding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding ?? AppTheme.layout.cardPadding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                switch style {
                case .gradient:
                    shape.fill(AppTheme.gradient.auroraPrimary)
                case .flat:
                    shape.fill(AppTheme.color.bg.surface)
                        .overlay { shape.strokeBorder(colorSchemeContrast == .increased
                            ? AppTheme.color.border.strong : AppTheme.color.border.subtle, lineWidth: 1) }
                case .standard:
                    Color.clear.echoSurface(.level1, in: shape)
                case .raised:
                    Color.clear.echoSurface(.level2, in: shape)
                }
            }
            .foregroundStyle(style == .gradient ? AppTheme.color.content.onAccent : AppTheme.color.content.primary)
    }
}

/// Basılabilir kart; basılı halde hafifçe küçülür (§4.4 `.interactive`).
struct EchoInteractiveCard<Content: View>: View {
    private let style: EchoCardStyle
    private let action: () -> Void
    private let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(style: EchoCardStyle = .standard, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.style = style
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            EchoCard(style: style) { content }
        }
        .buttonStyle(EchoInteractiveCardStyle(reduceMotion: reduceMotion))
    }
}

private struct EchoInteractiveCardStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

#Preview("Kartlar") {
    ScrollView {
        VStack(spacing: AppTheme.space.sm) {
            EchoCard { Text(verbatim: "Standart kart").echoTextStyle(.body) }
            EchoCard(style: .flat) { Text(verbatim: "Düz kart").echoTextStyle(.body) }
            EchoCard(style: .raised) { Text(verbatim: "Yükseltilmiş kart").echoTextStyle(.body) }
            EchoCard(style: .gradient) { Text(verbatim: "Gradient kart").echoTextStyle(.title3) }
            EchoInteractiveCard(action: {}) { Text(verbatim: "Dokunulabilir kart").echoTextStyle(.body) }
        }
        .padding(AppTheme.layout.screenHorizontalPadding)
    }
    .background(AppTheme.color.bg.canvas)
}
