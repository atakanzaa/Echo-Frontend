import SwiftUI

/// Chip (implementation.md §4.3). Mood varyantı rengi tek başına kullanmaz; şekil ikonuyla gelir.
nonisolated enum EchoChipStyle: Sendable, Equatable {
    case `static`
    case selectable(isSelected: Bool)
    case removable
    case mood(EchoMoodLevel)
}

struct EchoChip: View {
    private let title: String
    private let style: EchoChipStyle
    private let systemImage: String?
    private let action: (() -> Void)?

    init(_ title: String, style: EchoChipStyle = .static, systemImage: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        let content = HStack(spacing: AppTheme.space.xxxs) {
            if case let .mood(level) = style {

                EchoMoodGlyph(level: level, size: 12)
            } else if let systemImage {

                Image(systemName: systemImage).font(.system(size: AppTheme.icon.sm, weight: .medium))
            }
            Text(title).echoTextStyle(.subhead)
            if style == .removable {

                Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, AppTheme.space.xs)
        .frame(minHeight: 32)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.xs, style: .continuous).fill(background))
        .overlay {
            if isSelected {

                RoundedRectangle(cornerRadius: AppTheme.radius.xs, style: .continuous)
                    .strokeBorder(AppTheme.color.border.accent, lineWidth: 1)
            }
        }

        if let action {

            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        } else {
            content
        }
    }

    private var isSelected: Bool {
        if case let .selectable(isSelected) = style { return isSelected }
        return false
    }

    private var foreground: Color {
        switch style {
        case .static, .removable: AppTheme.color.content.secondary
        case .selectable(let isSelected): isSelected ? AppTheme.color.content.accent : AppTheme.color.content.secondary
        case .mood: AppTheme.color.content.primary
        }
    }

    private var background: Color {
        switch style {
        case .static, .removable: AppTheme.color.bg.surfaceSunken
        case .selectable(let isSelected): isSelected ? AppTheme.color.bg.accentSoft : AppTheme.color.bg.surfaceSunken
        case .mood(let level): level.color.opacity(0.12)
        }
    }
}

#Preview("Chip") {
    VStack(alignment: .leading, spacing: AppTheme.space.xs) {
        EchoChip("uyku")
        EchoChip("iş", style: .selectable(isSelected: true)) {}
        EchoChip("spor", style: .removable) {}
        EchoChip("Sakin", style: .mood(.good))
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
