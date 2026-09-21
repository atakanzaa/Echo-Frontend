import SwiftUI

/// Açılış: yapılandırma ve oturum birlikte yüklenir. Sürüm kararı sunucudan gelir (rules.md §2).
struct LaunchView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(spacing: AppTheme.space.md) {
            EchoBrandMark(size: 140, tint: AppTheme.color.accent.primary)
            Text("launch.preparing")
                .echoTextStyle(.callout)
                .foregroundStyle(AppTheme.color.content.secondary)
            if let error = environment.remoteConfig.error ?? environment.session.restoreError {

                VStack(spacing: AppTheme.space.xs) {
                    Text(error.serverMessage ?? String(localized: String.LocalizationValue(error.messageKey ?? "error.unexpected")))
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                        .multilineTextAlignment(.center)
                    EchoButton("launch.retry", variant: .secondary, size: .sm) {
                        Task { await load() }
                    }
                }
                .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
        .task { await load() }
    }

    private func load() async {
        async let config: Void = environment.remoteConfig.load()
        async let session: Void = environment.session.restore()
        _ = await (config, session)
    }
}

/// Sunucu zorunlu güncelleme dediğinde uygulama akışı burada durur.
struct UpdateRequiredView: View {
    let storeURL: URL?
    @Environment(\.openURL) private var openURL

    var body: some View {
        EchoEmptyState("update.requiredTitle", message: "update.requiredBody", systemImage: "arrow.down.circle") {
            if let storeURL {

                EchoButton("update.openStore", variant: .primary) { openURL(storeURL) }
            }
        }
        .frame(maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
    }
}

#Preview("Açılış") {
    UpdateRequiredView(storeURL: URL(string: "https://apps.apple.com"))
}
