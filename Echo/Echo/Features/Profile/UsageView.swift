import SwiftUI

/// Kullanım hakkı ekranı: gün ve ay pencereleri, yenilenme zamanları ve (ücretsizde) premium teklifi.
/// Yüzde ve yenilenme anı sunucudan gelir; ekran yalnız gösterir.
struct UsageView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                Text("usage.intro")
                    .echoTextStyle(.body)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let usage = environment.usage.usage {

                    if usage.state != .ok {

                        // Premium teklifi aşağıdaki plan bölümünde; şeritte tekrarlanmaz.
                        UsageNotice(usage: usage)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(usage.windows.enumerated()), id: \.element.id) { index, window in

                            windowRow(window)
                            if index < usage.windows.count - 1 { EchoDivider() }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous).fill(AppTheme.color.bg.surface))
                    plan(usage)
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.vertical, AppTheme.space.md)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("usage.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await environment.usage.refresh() }
        .refreshable { await environment.usage.refresh() }
    }

    private func windowRow(_ window: AIUsage.Window) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(title(window.scope))
                    .echoTextStyle(.headline)
                    .foregroundStyle(AppTheme.color.content.primary)
                Spacer()
                Text(String(format: String(localized: "usage.percentUsed"), window.usedPercent))
                    .echoTextStyle(.subhead).monospacedDigit()
                    .foregroundStyle(window.state == .exhausted ? AppTheme.color.feedback.danger : AppTheme.color.content.secondary)
            }
            UsageBar(percent: window.usedPercent, state: window.state)
            UsageCountdown(resetsAt: window.resetsAt)
                .echoTextStyle(.footnote)
                .foregroundStyle(AppTheme.color.content.tertiary)
        }
        .padding(AppTheme.space.md)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func plan(_ usage: AIUsage) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            Text(usage.isPremium ? "usage.plan.premium" : "usage.plan.free")
                .echoTextStyle(.subhead).fontWeight(.semibold)
                .foregroundStyle(AppTheme.color.content.primary)
            Text("usage.alwaysOpen")
                .echoTextStyle(.footnote)
                .foregroundStyle(AppTheme.color.content.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !usage.isPremium {

                EchoButton("usage.upgrade", variant: .secondary) { router.present(.paywall) }
                    .padding(.top, AppTheme.space.xxs)
            }
        }
    }

    private func title(_ scope: AIUsage.Scope) -> LocalizedStringKey {
        switch scope {
        case .day: "usage.window.day"
        case .month: "usage.window.month"
        case .service: "usage.window.service"
        case .unknown: "usage.window.other"
        }
    }
}
