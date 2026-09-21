import SwiftUI

/// İkon butonu (implementation.md §4.2). Dokunma alanı her zaman en az 44×44'tür.
nonisolated enum EchoIconButtonVariant: Sendable {
    case plain
    case soft
    case filled
    /// Yalnız medya (kayıt, görsel) üstünde kullanılır.
    case glass

    var foreground: Color {
        switch self {
        case .plain: AppTheme.color.content.secondary
        case .soft: AppTheme.color.content.accent
        case .filled: AppTheme.color.content.onAccent
        case .glass: AppTheme.color.content.onAccent
        }
    }

    var background: Color? {
        switch self {
        case .plain, .glass: nil
        case .soft: AppTheme.color.bg.accentSoft
        case .filled: AppTheme.color.accent.primary
        }
    }
}

struct EchoIconButton: View {
    private let systemImage: String
    private let accessibilityTitle: LocalizedStringKey
    private let variant: EchoIconButtonVariant
    private let isCircular: Bool
    private let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    init(_ systemImage: String,
         accessibilityTitle: LocalizedStringKey,
         variant: EchoIconButtonVariant = .plain,
         isCircular: Bool = true,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityTitle = accessibilityTitle
        self.variant = variant
        self.isCircular = isCircular
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: AppTheme.icon.md, weight: .medium))
        }
        .buttonStyle(EchoIconButtonStyle(variant: variant, isCircular: isCircular))
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(Text(accessibilityTitle))
    }
}

private struct EchoIconButtonStyle: ButtonStyle {
    let variant: EchoIconButtonVariant
    let isCircular: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = isCircular
            ? AnyInsettableShape(Circle())
            : AnyInsettableShape(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous))
        return configuration.label
            .foregroundStyle(variant.foreground)
            .frame(width: AppTheme.layout.minTouchTarget, height: AppTheme.layout.minTouchTarget)
            .background {
                if variant == .glass {

                    shape.fill(.ultraThinMaterial)
                } else if let background = variant.background {

                    shape.fill(background)
                }
            }
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

/// Şekil seçimini tip silmeden taşımak için ince sarmalayıcı.
nonisolated struct AnyInsettableShape: InsettableShape {
    private let pathBuilder: @Sendable (CGRect) -> Path
    private let insetBuilder: @Sendable (CGFloat) -> AnyInsettableShape

    init<S: InsettableShape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
        insetBuilder = { amount in AnyInsettableShape(shape.inset(by: amount)) }
    }

    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
    func inset(by amount: CGFloat) -> AnyInsettableShape { insetBuilder(amount) }
}

#Preview("İkon butonları") {
    HStack(spacing: AppTheme.space.sm) {
        EchoIconButton("bell", accessibilityTitle: "Bildirimler") {}
        EchoIconButton("plus", accessibilityTitle: "Ekle", variant: .soft) {}
        EchoIconButton("mic.fill", accessibilityTitle: "Kaydet", variant: .filled) {}
        EchoIconButton("xmark", accessibilityTitle: "common.close", variant: .plain, isCircular: false) {}
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
