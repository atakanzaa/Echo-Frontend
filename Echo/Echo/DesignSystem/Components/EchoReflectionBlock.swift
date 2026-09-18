import SwiftUI

/// Echo'nun imzası: AI yansımasını günlük metninin içine gömen blok (implementation.md §4.21).
/// Metin sunucudan gelir; uygulama yeniden yazmaz.
struct EchoReflectionBlock<Actions: View>: View {
    private let text: String
    private let actions: Actions

    init(text: String, @ViewBuilder actions: () -> Actions = { EmptyView() }) {
        self.text = text
        self.actions = actions()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(AppTheme.color.accent.primary)
                .frame(width: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                HStack(spacing: AppTheme.space.xxxs) {
                    EchoRippleView(ringCount: 2, intensity: 0.5, isAnimating: false)
                        .frame(width: 14, height: 14)
                    Text("common.appName")
                        .echoTextStyle(.caption2)
                        .textCase(.uppercase)
                        .foregroundStyle(AppTheme.color.content.accent)
                }
                Text(text)
                    .echoTextStyle(.entryQuote)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .fixedSize(horizontal: false, vertical: true)
                actions
            }
            .padding(.vertical, AppTheme.space.sm)
            .padding(.leading, AppTheme.space.md)
            .padding(.trailing, AppTheme.space.sm)
        }
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous).fill(AppTheme.color.bg.accentSoft))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous))
    }
}

#Preview("Yansıma bloğu") {
    EchoReflectionBlock(text: "Bugün yürüyüşün sana iyi geldiğini yazmışsın. Bu küçük molaların hangi günlerde tekrarlandığını fark ettin mi?") {
        HStack(spacing: AppTheme.space.xs) {
            EchoButton(verbatimTitle: "Devam et", variant: .ghost, size: .sm) {}
        }
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
