#if DEBUG
import SwiftUI
import UIKit

/// Tüm tasarım token'larını görsel olarak listeleyen geliştirici ekranı (implementation.md P0.7).
/// Token adları tanımlayıcı olduğu için yerelleştirilmez.
struct TokenGalleryView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isMotionToggled = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                appearancePicker
                colorSection
                gradientSection
                typographySection
                spacingSection
                radiusSection
                elevationSection
                motionSection
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.vertical, AppTheme.space.lg)
        }
        .background(AppTheme.color.bg.canvas.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Token Gallery"))
    }

    private var appearancePicker: some View {
        @Bindable var themeManager = themeManager
        return Picker(selection: $themeManager.appearance) {
            ForEach(AppAppearance.allCases) { appearance in
                Text(verbatim: appearance.rawValue).tag(appearance)
            }
        } label: {
            Text(verbatim: "Appearance")
        }
        .pickerStyle(.segmented)
    }

    private var colorSection: some View {
        section("Color") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: AppTheme.space.xs)], spacing: AppTheme.space.xs) {
                ForEach(EchoColorAsset.allCases, id: \.self) { asset in
                    VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                        RoundedRectangle.echoRounded(AppTheme.radius.sm)
                            .fill(asset.color)
                            .frame(height: 44)
                            .overlay {
                                RoundedRectangle.echoRounded(AppTheme.radius.sm)
                                    .strokeBorder(AppTheme.color.border.default, lineWidth: 1)
                            }
                        Text(verbatim: asset.rawValue)
                            .echoTextStyle(.caption)
                            .foregroundStyle(UIColor(named: asset.rawValue) == nil ? AppTheme.color.feedback.danger : AppTheme.color.content.secondary)
                    }
                }
            }
        }
    }

    private var gradientSection: some View {
        section("Gradient") {
            HStack(spacing: AppTheme.space.xs) {
                RoundedRectangle.echoRounded(AppTheme.radius.md).fill(AppTheme.gradient.auroraPrimary)
                RoundedRectangle.echoRounded(AppTheme.radius.md).fill(AppTheme.gradient.auroraRecord)
                RoundedRectangle.echoRounded(AppTheme.radius.md).fill(AppTheme.gradient.auroraCelebration)
            }
            .frame(height: 72)
        }
    }

    private var typographySection: some View {
        section("Typography") {
            VStack(alignment: .leading, spacing: AppTheme.space.sm) {
                ForEach(EchoTextStyle.allCases, id: \.self) { style in
                    VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                        Text(verbatim: "\(style) · \(Int(style.size))/\(Int(style.lineHeight))")
                            .echoTextStyle(.caption2)
                            .foregroundStyle(AppTheme.color.content.tertiary)
                        Text(verbatim: "Echo 0123 · Bugün kendimi dingin hissettim.")
                            .echoTextStyle(style)
                            .foregroundStyle(AppTheme.color.content.primary)
                    }
                }
            }
        }
    }

    private var spacingSection: some View {
        let scale = AppTheme.space
        let values: [(String, CGFloat)] = [("xxxxs", scale.xxxxs), ("xxxs", scale.xxxs), ("xxs", scale.xxs), ("xs", scale.xs), ("sm", scale.sm),
                                          ("md", scale.md), ("lg", scale.lg), ("xl", scale.xl), ("xxl", scale.xxl), ("xxxl", scale.xxxl), ("xxxxl", scale.xxxxl)]
        return section("Spacing") {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                ForEach(values, id: \.0) { name, value in
                    HStack(spacing: AppTheme.space.xs) {
                        Text(verbatim: "\(name) \(Int(value))")
                            .echoTextStyle(.caption)
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .frame(width: 80, alignment: .leading)
                        Rectangle()
                            .fill(AppTheme.color.accent.primary)
                            .frame(width: value, height: AppTheme.space.xs)
                    }
                }
            }
        }
    }

    private var radiusSection: some View {
        let scale = AppTheme.radius
        let values: [(String, CGFloat)] = [("xs", scale.xs), ("sm", scale.sm), ("md", scale.md), ("lg", scale.lg), ("xl", scale.xl), ("full", scale.full)]
        return section("Radius") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: AppTheme.space.xs)], spacing: AppTheme.space.xs) {
                ForEach(values, id: \.0) { name, value in
                    RoundedRectangle.echoRounded(value)
                        .fill(AppTheme.color.bg.accentSoft)
                        .frame(height: 64)
                        .overlay {
                            Text(verbatim: name)
                                .echoTextStyle(.caption)
                                .foregroundStyle(AppTheme.color.content.accent)
                        }
                }
            }
        }
    }

    private var elevationSection: some View {
        section("Elevation") {
            VStack(spacing: AppTheme.space.md) {
                ForEach(EchoElevation.allCases, id: \.self) { level in
                    Text(verbatim: "\(level)")
                        .echoTextStyle(.headline)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .frame(maxWidth: .infinity, minHeight: AppTheme.layout.listRowMinHeight)
                        .echoSurface(level, cornerRadius: AppTheme.radius.lg)
                }
            }
        }
    }

    private var motionSection: some View {
        let animations: [(String, Animation)] = [("snappy", AppTheme.motion.snappy), ("smooth", AppTheme.motion.smooth),
                                                 ("bouncy", AppTheme.motion.bouncy), ("standard", AppTheme.motion.standard)]
        return section("Motion") {
            VStack(alignment: .leading, spacing: AppTheme.space.sm) {
                ForEach(animations, id: \.0) { name, animation in
                    Button {
                        withAnimation(AppTheme.motion.resolved(animation, reduceMotion: reduceMotion)) {
                            isMotionToggled.toggle()
                        }
                    } label: {
                        HStack {
                            Text(verbatim: name)
                                .echoTextStyle(.subhead)
                                .foregroundStyle(AppTheme.color.content.accent)
                                .frame(width: 80, alignment: .leading)
                            Circle()
                                .fill(AppTheme.color.accent.secondary)
                                .frame(width: AppTheme.icon.lg, height: AppTheme.icon.lg)
                                .frame(maxWidth: .infinity, alignment: isMotionToggled ? .trailing : .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            Text(verbatim: title.uppercased())
                .echoTextStyle(.caption2)
                .foregroundStyle(AppTheme.color.content.tertiary)
            content()
        }
    }
}

#Preview("Light") {
    NavigationStack { TokenGalleryView() }
        .environment(ThemeManager())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack { TokenGalleryView() }
        .environment(ThemeManager())
        .preferredColorScheme(.dark)
}
#endif
