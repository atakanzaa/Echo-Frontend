import SwiftUI

@main
struct EchoApp: App {
    @State private var environment: AppEnvironment?
    @State private var startupError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {

                    RootView()
                        .environment(environment)
                        .environment(environment.theme)
                        .preferredColorScheme(environment.theme.appearance.colorScheme)
                        .tint(AppTheme.color.accent.primary)
                } else {
                    // Yapılandırma okunamazsa uygulama sahte bir ekranla devam etmez.
                    StartupFailureView(message: startupError)
                }
            }
            .task { start() }
        }
    }

    private func start() {
        guard environment == nil else { return }
        do {
            environment = try AppEnvironment.make()
        } catch {
            startupError = String(describing: error)
        }
    }
}

/// Sunucu adresi gibi derleme yapılandırması eksikse gösterilir; kullanıcıya sahte içerik sunulmaz.
struct StartupFailureView: View {
    let message: String?

    var body: some View {
        EchoEmptyState("error.unexpected", message: "error.network", systemImage: "exclamationmark.triangle")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.color.bg.canvas)
    }
}
