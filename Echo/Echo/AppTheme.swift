import SwiftUI

enum AppTheme {}

extension AppTheme {
    enum Colors {
        static func background(_ s: ColorScheme) -> Color {
            s == .dark
                ? Color(red: 0.078, green: 0.039, blue: 0.114)
                : Color(red: 0.972, green: 0.961, blue: 0.984)
        }

        static func surface(_ s: ColorScheme) -> Color {
            s == .dark
                ? Color(red: 0.149, green: 0.098, blue: 0.196)
                : Color(red: 0.949, green: 0.929, blue: 0.969)
        }

        static func surfaceElevated(_ s: ColorScheme) -> Color {
            s == .dark
                ? Color(red: 0.165, green: 0.114, blue: 0.212)
                : Color(red: 0.929, green: 0.906, blue: 0.957)
        }

        static func surfaceOverlay(_ s: ColorScheme) -> Color {
            s == .dark ? Color.black.opacity(0.55) : Color.black.opacity(0.3)
        }

        static var accent: Color {
            Color(red: 0.498, green: 0.075, blue: 0.929)
        }

        static var accentSecondary: Color {
            Color(red: 0.369, green: 0.055, blue: 0.702)
        }

        static func accentSoft(_ s: ColorScheme) -> Color {
            s == .dark ? accent.opacity(0.15) : accent.opacity(0.10)
        }

        static var accentForeground: Color { .white }

        static func tabActive(_: ColorScheme) -> Color {
            accent
        }

        static func textPrimary(_ s: ColorScheme) -> Color {
            s == .dark ? .white : Color(red: 0.102, green: 0.063, blue: 0.141)
        }

        static func textSecondary(_ s: ColorScheme) -> Color {
            s == .dark
                ? Color(red: 0.820, green: 0.839, blue: 0.855)
                : Color(red: 0.310, green: 0.235, blue: 0.400)
        }

        static func textMuted(_ s: ColorScheme) -> Color {
            s == .dark
                ? Color(red: 0.678, green: 0.573, blue: 0.792)
                : Color(red: 0.400, green: 0.318, blue: 0.502)
        }

        static func textDisabled(_ s: ColorScheme) -> Color {
            s == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.25)
        }

        static var textOnAccent: Color { .white }

        static var destructive: Color {
            Color(red: 0.937, green: 0.267, blue: 0.267)
        }

        static func destructiveSoft(_ s: ColorScheme) -> Color {
            destructive.opacity(s == .dark ? 0.15 : 0.10)
        }

        static var success: Color {
            Color(red: 0.133, green: 0.769, blue: 0.368)
        }

        static func successSoft(_ s: ColorScheme) -> Color {
            success.opacity(s == .dark ? 0.15 : 0.10)
        }

        static var warning: Color {
            Color(red: 0.933, green: 0.741, blue: 0.169)
        }

        static func warningSoft(_ s: ColorScheme) -> Color {
            warning.opacity(s == .dark ? 0.15 : 0.10)
        }

        static var processing: Color {
            Color(red: 0.498, green: 0.075, blue: 0.929)
        }

        static func border(_ s: ColorScheme) -> Color {
            s == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
        }

        static func borderSubtle(_ s: ColorScheme) -> Color {
            s == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04)
        }

        static var moodVeryPositive: Color  { Color(red: 0.157, green: 0.631, blue: 0.569) }
        static var moodPositive: Color      { Color(red: 0.133, green: 0.769, blue: 0.368) }
        static var moodNeutral: Color       { Color(red: 0.498, green: 0.075, blue: 0.929) }
        static var moodSlightlyNeg: Color   { Color(red: 0.933, green: 0.741, blue: 0.169) }
        static var moodNegative: Color      { Color(red: 0.937, green: 0.267, blue: 0.267) }
        static var moodVeryNeg: Color       { Color(red: 0.800, green: 0.100, blue: 0.100) }

        static var gold: Color {
            Color(red: 0.933, green: 0.741, blue: 0.169)
        }

        static func goldSoft(_ s: ColorScheme) -> Color {
            gold.opacity(s == .dark ? 0.15 : 0.10)
        }
    }
}

extension AppTheme {
    enum Typography {
        static var display:   Font { .system(size: 34, weight: .bold) }
        static var heading1:  Font { .system(size: 28, weight: .bold) }
        static var heading2:  Font { .system(size: 22, weight: .semibold) }
        static var heading3:  Font { .system(size: 17, weight: .semibold) }

        static var body:      Font { .system(size: 16, weight: .regular) }
        static var bodyEm:    Font { .system(size: 16, weight: .semibold) }
        static var bodyLight: Font { .system(size: 16, weight: .light) }

        static var caption:   Font { .system(size: 13, weight: .regular) }
        static var label:     Font { .system(size: 12, weight: .medium) }
        static var micro:     Font { .system(size: 10, weight: .regular) }

        static var mono:      Font { .system(size: 52, weight: .thin, design: .monospaced) }
        static var monoSm:    Font { .system(size: 22, weight: .light, design: .monospaced) }
    }
}

extension AppTheme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let section: CGFloat = 64

        static let radiusSm: CGFloat = 8
        static let radiusMd: CGFloat = 12
        static let radiusLg: CGFloat = 16
        static let radiusXl: CGFloat = 24
        static let radiusFull: CGFloat = 999
    }
}

extension AppTheme {
    enum Layout {
        static let screenHorizontal: CGFloat = Spacing.lg
        static let headerTop: CGFloat = Spacing.xs
        static let headerBottom: CGFloat = Spacing.sm
        static let sectionGap: CGFloat = Spacing.md
        static let cardPadding: CGFloat = Spacing.md
        static let cardRadius: CGFloat = Spacing.radiusLg
        static let navAwareBottomInset: CGFloat = Spacing.xxl + Spacing.lg
        static let controlHeight: CGFloat = 52
        static let compactControlHeight: CGFloat = 44
        static let iconButtonSize: CGFloat = 40
        static let compactIconButtonSize: CGFloat = 32
        static let fieldMinHeight: CGFloat = 48
        static let rowMinHeight: CGFloat = 56
        static let chipHPadding: CGFloat = 10
        static let chipVPadding: CGFloat = 6
        static let bottomFloatingOffset: CGFloat = navAwareBottomInset + Spacing.sm
        static let sheetBottomInset: CGFloat = Spacing.xl
    }
}

extension AppTheme {
    enum Shadows {
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static func shadowSm(_ s: ColorScheme) -> ShadowStyle {
            ShadowStyle(color: s == .dark ? .black.opacity(0.3) : .black.opacity(0.10), radius: 6, x: 0, y: 2)
        }

        static func shadowMd(_ s: ColorScheme) -> ShadowStyle {
            ShadowStyle(color: s == .dark ? .black.opacity(0.4) : .black.opacity(0.15), radius: 12, x: 0, y: 4)
        }

        static func shadowLg(_ s: ColorScheme) -> ShadowStyle {
            ShadowStyle(color: s == .dark ? .black.opacity(0.5) : .black.opacity(0.20), radius: 24, x: 0, y: 8)
        }

        static func accentShadow(opacity: Double = 0.45) -> ShadowStyle {
            ShadowStyle(color: AppTheme.Colors.accent.opacity(opacity), radius: 20, x: 0, y: 6)
        }
    }
}

extension AppTheme {
    static var premiumGold: LinearGradient { Gradients.gold }

    enum Gradients {
        static var accent: LinearGradient {
            LinearGradient(
                colors: [AppTheme.Colors.accent, AppTheme.Colors.accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func micButton(recording: Bool) -> LinearGradient {
            recording
                ? LinearGradient(
                    colors: [
                        Color(red: 0.937, green: 0.267, blue: 0.267),
                        Color(red: 0.700, green: 0.100, blue: 0.100)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : accent
        }

        static var gold: LinearGradient {
            LinearGradient(
                colors: [
                    Color(red: 0.933, green: 0.741, blue: 0.169),
                    Color(red: 1.000, green: 0.576, blue: 0.000)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func surfaceFade(_ s: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [
                    AppTheme.Colors.surface(s).opacity(0),
                    AppTheme.Colors.surface(s)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

extension View {
    func themeShadow(_ style: AppTheme.Shadows.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    func themeCard(_ s: ColorScheme) -> some View {
        self
            .background(AppTheme.Colors.surface(s))
            .cornerRadius(AppTheme.Spacing.radiusMd)
            .themeShadow(AppTheme.Shadows.shadowSm(s))
    }

    func echoCard(
        _ s: ColorScheme,
        elevated: Bool = true,
        radius: CGFloat = AppTheme.Layout.cardRadius,
        bordered: Bool = true
    ) -> some View {
        modifier(EchoCardModifier(colorScheme: s, elevated: elevated, radius: radius, bordered: bordered))
    }

    func echoInputField(_ s: ColorScheme, elevated: Bool = true) -> some View {
        modifier(EchoInputFieldModifier(colorScheme: s, elevated: elevated))
    }

    func echoPrimaryButton(_ s: ColorScheme, enabled: Bool = true, radius: CGFloat = AppTheme.Spacing.radiusFull) -> some View {
        modifier(EchoPrimaryButtonModifier(colorScheme: s, enabled: enabled, radius: radius))
    }

    func echoSecondaryButton(_ s: ColorScheme, radius: CGFloat = AppTheme.Spacing.radiusMd) -> some View {
        modifier(EchoSecondaryButtonModifier(colorScheme: s, radius: radius))
    }

    func echoDestructiveButton(_ s: ColorScheme, radius: CGFloat = AppTheme.Spacing.radiusMd) -> some View {
        modifier(EchoDestructiveButtonModifier(colorScheme: s, radius: radius))
    }

    func echoIconContainer(_ color: Color, size: CGFloat = AppTheme.Layout.iconButtonSize, radius: CGFloat = AppTheme.Spacing.radiusSm) -> some View {
        modifier(EchoIconContainerModifier(color: color, size: size, radius: radius))
    }
}

private struct EchoCardModifier: ViewModifier {
    let colorScheme: ColorScheme
    let elevated: Bool
    let radius: CGFloat
    let bordered: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(elevated ? AppTheme.Colors.surfaceElevated(colorScheme) : AppTheme.Colors.surface(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(bordered ? AppTheme.Colors.borderSubtle(colorScheme) : Color.clear, lineWidth: 1)
            )
    }
}

private struct EchoInputFieldModifier: ViewModifier {
    let colorScheme: ColorScheme
    let elevated: Bool

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
            .frame(minHeight: AppTheme.Layout.fieldMinHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd, style: .continuous)
                    .fill(elevated ? AppTheme.Colors.surfaceElevated(colorScheme) : AppTheme.Colors.surface(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
            )
    }
}

private struct EchoPrimaryButtonModifier: ViewModifier {
    let colorScheme: ColorScheme
    let enabled: Bool
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.bodyEm)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.controlHeight)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(AppTheme.Gradients.accent) : AnyShapeStyle(AppTheme.Colors.textDisabled(colorScheme).opacity(0.45)))
            }
            .opacity(enabled ? 1 : 0.65)
    }
}

private struct EchoSecondaryButtonModifier: ViewModifier {
    let colorScheme: ColorScheme
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.bodyEm)
            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.controlHeight)
            .background(AppTheme.Colors.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
            )
    }
}

private struct EchoDestructiveButtonModifier: ViewModifier {
    let colorScheme: ColorScheme
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.bodyEm)
            .foregroundColor(AppTheme.Colors.destructive)
            .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.controlHeight)
            .background(AppTheme.Colors.destructiveSoft(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.destructive.opacity(0.25), lineWidth: 1)
            )
    }
}

private struct EchoIconContainerModifier: ViewModifier {
    let color: Color
    let size: CGFloat
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
