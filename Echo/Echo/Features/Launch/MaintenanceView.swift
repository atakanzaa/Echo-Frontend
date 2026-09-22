import SwiftUI

/// Sunucu bakımdayken uygulama burada bekler; bakım bitince kendiliğinden devam eder.
struct MaintenanceView: View {
    let message: String
    /// Oturum kapalıysa giriş formu açılabilir: giriş bakımda da çalışır, yönetici paneli bununla açılır.
    let allowsSignIn: Bool
    let onSignIn: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var isChecking = false

    var body: some View {
        EchoEmptyState("maintenance.title", systemImage: "wrench.and.screwdriver") {
            VStack(spacing: AppTheme.space.xs) {
                // Sunucu metni çevrilmez ve biçim dizesi olarak yorumlanmaz.
                Text(verbatim: message)
                    .echoTextStyle(.callout)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppTheme.space.xs)
                EchoButton("maintenance.retry", variant: .primary, isLoading: isChecking) {
                    Task { await check() }
                }
                if allowsSignIn {

                    EchoButton("maintenance.signIn", variant: .ghost, size: .sm, action: onSignIn)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
        .task {
            // Sunucu Retry-After ile iki dakika önerir; ekran açıkken dakikada bir bakılır.
            while !Task.isCancelled {

                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                await check()
            }
        }
    }

    private func check() async {
        isChecking = true
        await environment.remoteConfig.load()
        if environment.remoteConfig.maintenanceMessage == nil, environment.session.state == .restoring {

            await environment.session.restore()
        }
        isChecking = false
    }
}
