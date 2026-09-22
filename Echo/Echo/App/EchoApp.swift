import OSLog
import SwiftUI

@main
struct EchoApp: App {
    @UIApplicationDelegateAdaptor(EchoAppDelegate.self) private var appDelegate
    @State private var environment: AppEnvironment?
    @State private var startupError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-EchoMoodChartPreview") {

                    MoodChartGallery().preferredColorScheme(.dark)
                } else if ProcessInfo.processInfo.arguments.contains("-EchoShellPreview") {

                    ShellPreviewHost()
                } else if ProcessInfo.processInfo.arguments.contains("-EchoAdminPreview") {

                    AdminPreviewHost()
                } else if let notice = PreviewLaunch.argument("-EchoNoticePreview") {

                    NoticePreviewHost(name: notice)
                } else if let usage = PreviewLaunch.argument("-EchoUsagePreview") {

                    UsagePreviewHost(name: usage).preferredColorScheme(.dark).tint(AppTheme.color.accent.primary)
                } else if let preview = PreviewLaunch.current {

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

    static func argument(_ flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
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

/// Yalnız DEBUG: `-EchoShellPreview` sekmeli ana kabuğu sahte oturumla açar; sekme ve sunum akışları giriş yapmadan denenir.
/// `-EchoRouteSweep` eklenirse her sekme, her hedef ve her sayfa sırayla açılıp kapatılır; çökme son "start" satırında kalır.
/// Yalnız DEBUG: `-EchoNoticePreview <maintenance|ai_paused|community_frozen|registrations_closed|blocked>`
/// sunucu duyurularının ve engellenen oturumun ekranlarını sahte veriyle açar.
struct NoticePreviewHost: View {
    let name: String
    @State private var environment = AppEnvironment.preview(.morning)
    @State private var router = AppRouter()

    var body: some View {
        content
            .environment(environment)
            .environment(environment.theme)
            .preferredColorScheme(.dark)
            .tint(AppTheme.color.accent.primary)
            .task { apply() }
    }

    @ViewBuilder private var content: some View {
        switch name {
        case "maintenance":
            MaintenanceView(message: "Bakım 15:00'e kadar sürecek. Kayıtların güvende.", allowsSignIn: true) {}
        case "blocked", "registrations_closed":
            AuthFlowView()
        default:
            MainTabView(router: router)
        }
    }

    private func apply() {
        let messages = [
            "maintenance": "Bakım 15:00'e kadar sürecek. Kayıtların güvende.",
            "ai_paused": "Yapay zekâ analizi kısa süreliğine duraklatıldı. Kayıtların güvende; analiz sonra yapılacak.",
            "community_frozen": "Topluluk şu an salt okunur. Paylaşım ve yorum kısa süre sonra açılacak.",
            "registrations_closed": "Yeni hesap açılışı geçici olarak kapalı."
        ]
        if let message = messages[name] {

            environment.remoteConfig.applyPreview(notices: [.init(key: name, message: message)])
        }
        if name == "community_frozen" { router.selectedTab = .community }
        if name == "blocked" {

            environment.session.applyPreview(endedMessage: "Hesabın kullanım koşullarına aykırı etkinlik nedeniyle engellendi.")
        }
    }
}

struct ShellPreviewHost: View {
    @State private var environment = AppEnvironment.preview(.morning)
    @State private var router = AppRouter()
    private let sweeps = ProcessInfo.processInfo.arguments.contains("-EchoRouteSweep")
    private let log = Logger(subsystem: "Yel.Echo", category: "sweep")

    var body: some View {
        MainTabView(router: router)
            .environment(environment)
            .environment(environment.theme)
            .preferredColorScheme(.dark)
            .tint(AppTheme.color.accent.primary)
            .task { if sweeps { await sweep() } }
    }

    private func sweep() async {
        try? await Task.sleep(for: .seconds(2))
        for tab in AppTab.allCases {

            await step("tab.\(tab.rawValue)") { router.selectedTab = tab }
        }
        let destinations: [AppDestination] = [
            .journalEntry(id: "sweep"), .journalSearch, .insights, .moodTracker(periodDays: 7), .goals, .createGoal,
            .achievements, .achievementDetail(badgeKey: "first_entry"), .capsules, .createCapsule, .capsule(id: "sweep"),
            .coachSessions, .notifications, .communityPost(id: "sweep"), .settings, .editProfile, .privacyConsent,
            .notificationSettings, .subscription, .usage, .blockedAuthors
        ]
        for destination in destinations {

            await step("push.\(destination)") {
                router.popToRoot(.profile)
                router.push(destination, on: .profile)
            }
        }
        router.popToRoot(.profile)
        let sheets: [AppSheet] = [.composer, .coachChat(sessionId: nil), .composePost(prefilledText: nil), .paywall, .recording()]
        for sheet in sheets {

            await step("sheet.\(sheet.id)", seconds: 2) { router.present(sheet) }
            await step("dismiss.\(sheet.id)") { router.dismissSheet() }
        }
        log.notice("SWEEP done")
    }

    private func step(_ name: String, seconds: Double = 1.2, _ action: () -> Void) async {
        log.notice("SWEEP start \(name, privacy: .public)")
        action()
        try? await Task.sleep(for: .seconds(seconds))
        log.notice("SWEEP ok \(name, privacy: .public)")
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
