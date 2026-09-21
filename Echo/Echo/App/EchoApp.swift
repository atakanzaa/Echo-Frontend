import SwiftUI

@main
struct EchoApp: App {
    @State private var environment: AppEnvironment?
    @State private var startupError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let preview = PreviewLaunch.current {

                    PreviewLaunch.view(preview)
                } else {
                    appContent
                }
                #else
                appContent
                #endif
            }
            .task { start() }
        }
    }

    @ViewBuilder private var appContent: some View {
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

    private func start() {
        guard environment == nil else { return }
        do {
            environment = try AppEnvironment.make()
        } catch {
            startupError = String(describing: error)
        }
    }
}

#if DEBUG
/// Yalnız DEBUG: `-EchoTodayPreview <newUser|morning|evening|offline> [-EchoTheme light|dark]` ile
/// Bugün ekranının bir durumunu sahte veriyle açar; tasarım karşılaştırması içindir.
enum PreviewLaunch {
    struct Request {
        let state: TodayPreviewState
        let scheme: ColorScheme
    }

    static var current: Request? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-EchoTodayPreview"), index + 1 < arguments.count,
              let state = TodayPreviewState(rawValue: arguments[index + 1]) else { return nil }
        let themeIndex = arguments.firstIndex(of: "-EchoTheme")
        let theme = themeIndex.flatMap { $0 + 1 < arguments.count ? arguments[$0 + 1] : nil }
        return Request(state: state, scheme: theme == "light" ? .light : .dark)
    }

    @MainActor static func view(_ request: Request) -> some View {
        ZStack(alignment: .bottom) {
            TodayPreviewHost(state: request.state)
            EchoTabBar(selection: .constant(.today), isRecording: false, onRecordTap: {})
        }
        .background(AppTheme.color.bg.canvas)
        .preferredColorScheme(request.scheme)
        .tint(AppTheme.color.accent.primary)
    }
}
#endif

/// Sunucu adresi gibi derleme yapılandırması eksikse gösterilir; kullanıcıya sahte içerik sunulmaz.
struct StartupFailureView: View {
    let message: String?

    var body: some View {
        EchoEmptyState("error.unexpected", message: "error.network", systemImage: "exclamationmark.triangle")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.color.bg.canvas)
    }
}
