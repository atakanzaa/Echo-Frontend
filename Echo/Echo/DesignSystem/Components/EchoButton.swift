import SwiftUI

/// Buton varyantları (implementation.md §4.1). Bir ekranda en fazla bir `.primary` bulunur.
nonisolated enum EchoButtonVariant: Sendable {
    case primary
    case secondary
    case tertiary
    case ghost
    case destructive

    var background: Color? {
        switch self {
        case .primary: AppTheme.color.accent.primary
        case .secondary: AppTheme.color.bg.accentSoft
        case .tertiary: AppTheme.color.bg.surface
        case .ghost: nil
        case .destructive: AppTheme.color.feedback.danger
        }
    }

    var pressedBackground: Color? {
        switch self {
        case .primary: AppTheme.color.accent.primaryPressed
        case .secondary, .tertiary: AppTheme.color.bg.surfaceSunken
        case .ghost: AppTheme.color.bg.accentSoft
        case .destructive: AppTheme.color.feedback.danger.opacity(0.85)
        }
    }

    var foreground: Color {
        switch self {
        case .primary, .destructive: AppTheme.color.content.onAccent
        case .secondary, .ghost: AppTheme.color.content.accent
        case .tertiary: AppTheme.color.content.primary
        }
    }

    var border: Color? {
        self == .tertiary ? AppTheme.color.border.default : nil
    }
}

/// Buton boyutları (§4.1).
nonisolated enum EchoButtonSize: Sendable {
    case sm
    case md
    case lg
    case pill

    var height: CGFloat {
        switch self {
        case .sm: 36
        case .md, .pill: 46
        case .lg: 54
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm: 14
        case .md: 18
        case .lg: 22
        case .pill: 22
        }
    }

    var textStyle: EchoTextStyle {
        self == .sm ? .subhead : .headline
    }

    var radius: CGFloat {
        switch self {
        case .sm: AppTheme.radius.sm
        case .md, .lg: AppTheme.radius.md
        case .pill: AppTheme.radius.full
        }
    }
}

/// Uygulamanın tek buton bileşeni. Yıkıcı eylem çağıran tarafta onay ister.
struct EchoButton<Label: View>: View {
    private let variant: EchoButtonVariant
    private let size: EchoButtonSize
    private let fullWidth: Bool
    private let isLoading: Bool
    private let action: () -> Void
    private let label: Label

    init(variant: EchoButtonVariant = .primary,
         size: EchoButtonSize = .md,
         fullWidth: Bool = false,
         isLoading: Bool = false,
         action: @escaping () -> Void,
         @ViewBuilder label: () -> Label) {
        self.variant = variant
        self.size = size
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(EchoButtonStyle(variant: variant, size: size, fullWidth: fullWidth, isLoading: isLoading))
        .disabled(isLoading)
    }
}

extension EchoButton where Label == EchoButtonLabel {
    /// Metin ve opsiyonel SF Symbol ikonlarıyla standart yerleşim.
    init(_ title: LocalizedStringKey,
         variant: EchoButtonVariant = .primary,
         size: EchoButtonSize = .md,
         leadingIcon: String? = nil,
         trailingIcon: String? = nil,
         fullWidth: Bool = false,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.init(variant: variant, size: size, fullWidth: fullWidth, isLoading: isLoading, action: action) {
            EchoButtonLabel(title: title, leadingIcon: leadingIcon, trailingIcon: trailingIcon)
        }
    }
}

struct EchoButtonLabel: View {
    let title: LocalizedStringKey
    var leadingIcon: String?
    var trailingIcon: String?

    var body: some View {
        HStack(spacing: AppTheme.space.xxs) {
            if let leadingIcon {

                Image(systemName: leadingIcon).imageScale(.medium)
            }
            Text(title)
            if let trailingIcon {

                Image(systemName: trailingIcon).imageScale(.medium)
            }
        }
    }
}

private struct EchoButtonStyle: ButtonStyle {
    let variant: EchoButtonVariant
    let size: EchoButtonSize
    let fullWidth: Bool
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: size.radius, style: .continuous)
        return configuration.label
            .echoTextStyle(size.textStyle)
            .foregroundStyle(variant.foreground)
            // Yükleniyorken genişlik korunur; yerleşim zıplamaz.
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {

                    ProgressView().tint(variant.foreground)
                }
            }
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: size.height)
            .background {
                if let background = configuration.isPressed ? variant.pressedBackground : variant.background {

                    shape.fill(background)
                }
            }
            .overlay {
                if let border = variant.border {

                    shape.strokeBorder(border, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

#Preview("Butonlar") {
    ScrollView {
        VStack(alignment: .leading, spacing: AppTheme.space.sm) {
            EchoButton(verbatimTitle: "Kaydet", variant: .primary, size: .lg, fullWidth: true) {}
            EchoButton(verbatimTitle: "Devam et", variant: .secondary, leadingIcon: "arrow.right") {}
            EchoButton(verbatimTitle: "Vazgeç", variant: .tertiary) {}
            EchoButton(verbatimTitle: "Daha fazla", variant: .ghost, size: .sm) {}
            EchoButton(verbatimTitle: "Hesabı sil", variant: .destructive) {}
            EchoButton(verbatimTitle: "Yükleniyor", isLoading: true) {}
            EchoButton(verbatimTitle: "Pasif") {}.disabled(true)
        }
        .padding(AppTheme.layout.screenHorizontalPadding)
    }
    .background(AppTheme.color.bg.canvas)
}

#if DEBUG
extension EchoButton where Label == EchoButtonLabel {
    /// Yalnız preview için: katalogda anahtar oluşturmadan metin verir.
    init(verbatimTitle: String,
         variant: EchoButtonVariant = .primary,
         size: EchoButtonSize = .md,
         leadingIcon: String? = nil,
         trailingIcon: String? = nil,
         fullWidth: Bool = false,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.init(LocalizedStringKey(verbatimTitle), variant: variant, size: size, leadingIcon: leadingIcon,
                  trailingIcon: trailingIcon, fullWidth: fullWidth, isLoading: isLoading, action: action)
    }
}
#endif
