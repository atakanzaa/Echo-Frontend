import SwiftUI

/// 1px ayraç (implementation.md §4.32).
struct EchoDivider: View {
    var insetLeading: CGFloat = 0
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        Rectangle()
            .fill(colorSchemeContrast == .increased ? AppTheme.color.border.strong : AppTheme.color.border.subtle)
            .frame(height: 1)
            .padding(.leading, insetLeading)
            .accessibilityHidden(true)
    }
}

/// Bölüm başlığı: ALL CAPS caption2 + opsiyonel sağ aksiyon (§4.32).
struct EchoSectionHeader<Accessory: View>: View {
    private let title: LocalizedStringKey
    private let accessory: Accessory

    init(_ title: LocalizedStringKey, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .echoTextStyle(.caption2)
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.color.content.tertiary)
            Spacer(minLength: AppTheme.space.xs)
            accessory
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Sayı rozeti (§4.32). Sıfır gösterilmez; sayı sunucudan gelir.
struct EchoBadge: View {
    let count: Int
    var limit: Int = 99

    var body: some View {
        if count > 0 {

            Text(verbatim: count > limit ? "\(limit)+" : "\(count)")
                .echoTextStyle(.caption2)
                .foregroundStyle(AppTheme.color.content.onAccent)
                .padding(.horizontal, 6)
                .frame(minWidth: 18, minHeight: 18)
                .background(Capsule().fill(AppTheme.color.feedback.danger))
        }
    }
}

#Preview("Yardımcılar") {
    VStack(alignment: .leading, spacing: AppTheme.space.sm) {
        EchoSectionHeader("Bugün") {
            Text(verbatim: "Tümü").echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.accent)
        }
        EchoDivider()
        HStack(spacing: AppTheme.space.xs) {
            EchoBadge(count: 3)
            EchoBadge(count: 128)
            EchoBadge(count: 0)
        }
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
