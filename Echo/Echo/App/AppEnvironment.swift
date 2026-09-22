import Foundation
import Observation
import EchoAPI

/// Servis seti. Uygulamada canlı servisler, önizlemelerde sahte servisler verilir.
struct AppServices {
    var auth: any AuthServicing
    var appConfig: any AppConfigServicing
    var journal: any JournalServicing
    var goals: any GoalServicing
    var insights: any InsightsServicing
    var notifications: any NotificationServicing
    var capsules: any CapsuleServicing
    var coach: any CoachServicing
    var community: any CommunityServicing
    var subscription: any SubscriptionServicing
    var user: any UserServicing
    var usage: any UsageServicing
    var admin: any AdminServicing

    static func live(_ stack: EchoAPIStack) -> AppServices {
        AppServices(auth: LiveAuthService(stack: stack),
                    appConfig: LiveAppConfigService(stack: stack),
                    journal: LiveJournalService(stack: stack),
                    goals: LiveGoalService(stack: stack),
                    insights: LiveInsightsService(stack: stack),
                    notifications: LiveNotificationService(stack: stack),
                    capsules: LiveCapsuleService(stack: stack),
                    coach: LiveCoachService(stack: stack),
                    community: LiveCommunityService(stack: stack),
                    subscription: LiveSubscriptionService(stack: stack),
                    user: LiveUserService(stack: stack),
                    usage: LiveUsageService(stack: stack),
                    admin: LiveAdminService(stack: stack))
    }
}

/// Uygulamanın bağımlılık kökü: yapılandırma, ağ yığını, servisler ve durum depoları.
@Observable
@MainActor
final class AppEnvironment {
    let configuration: AppConfiguration
    let stack: EchoAPIStack
    let language: AppLanguageStore
    let theme: ThemeManager
    let appLock: AppLockManager

    let auth: any AuthServicing
    let appConfigService: any AppConfigServicing
    let journal: any JournalServicing
    let goals: any GoalServicing
    let insights: any InsightsServicing
    let notifications: any NotificationServicing
    let capsules: any CapsuleServicing
    let coach: any CoachServicing
    let community: any CommunityServicing
    let subscription: any SubscriptionServicing
    let user: any UserServicing
    let admin: any AdminServicing

    let session: SessionStore
    let remoteConfig: AppConfigStore
    let pendingJournals: PendingJournalStore
    let submissions: JournalSubmissionStore
    let usage: UsageStore
    let network = NetworkStatus()
    let push = PushRegistrar.shared
    @ObservationIgnored private var signalTasks: [Task<Void, Never>] = []

    init(configuration: AppConfiguration, stack: EchoAPIStack, language: AppLanguageStore, services: AppServices? = nil) {
        self.configuration = configuration
        self.stack = stack
        self.language = language
        theme = ThemeManager()
        appLock = AppLockManager()

        let services = services ?? .live(stack)
        auth = services.auth
        notifications = services.notifications
        appConfigService = services.appConfig
        journal = services.journal
        goals = services.goals
        insights = services.insights
        capsules = services.capsules
        coach = services.coach
        community = services.community
        subscription = services.subscription
        user = services.user
        admin = services.admin

        session = SessionStore(auth: services.auth, notifications: services.notifications, tokenStore: stack.tokenStore)
        remoteConfig = AppConfigStore(service: services.appConfig,
                                      appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        let pendingJournals = PendingJournalStore()
        self.pendingJournals = pendingJournals
        submissions = JournalSubmissionStore(journal: services.journal, pending: pendingJournals)
        usage = UsageStore(service: services.usage)
    }

    /// Sunucu adresi ve Keychain servisi Info.plist'ten gelir; adres kodda uydurulmaz.
    static func make() throws -> AppEnvironment {
        let configuration = try AppConfiguration.load()
        let language = AppLanguageStore()
        let stack = try EchoAPIStack.make(serverURL: configuration.apiBaseURL,
                                          keychainService: configuration.keychainService,
                                          language: language.headerProvider)
        let environment = AppEnvironment(configuration: configuration, stack: stack, language: language)
        environment.push.attach(environment.notifications)
        environment.observeServiceSignals()
        return environment
    }

    /// Bakım ve erişim engeli hangi ekrandan gelirse gelsin kökte karşılanır.
    private func observeServiceSignals() {
        guard signalTasks.isEmpty else { return }
        signalTasks.append(Task { [weak self] in
            for await note in NotificationCenter.default.notifications(named: ServiceSignal.maintenance) {
                let detail = note.userInfo?["detail"] as? String ?? ""
                self?.remoteConfig.reportMaintenance(detail)
            }
        })
        signalTasks.append(Task { [weak self] in
            for await note in NotificationCenter.default.notifications(named: ServiceSignal.accessBlocked) {
                let detail = note.userInfo?["detail"] as? String ?? ""
                guard let self, self.session.state.user != nil else { continue }
                await self.session.end(message: detail)
                self.push.signedOut()
                self.usage.clear()
            }
        })
    }

    /// Çıkış ve hesap silme: sunucu oturumu kapanır; bu kullanıcının cihazdaki gönderilmemiş kayıtları, ses dosyaları
    /// ve kullanım bilgisi silinir. Oturumun kendiliğinden düşmesi (süresi dolan token) bunları silmez; kullanıcı geri
    /// girince bekleyen kayıtlar gönderilir.
    func signOut() async {
        let userID = session.state.user?.id
        await session.signOut(pushToken: push.token)
        push.signedOut()
        pendingJournals.removeAll(ownedBy: userID)
        usage.clear()
    }

    /// Uygulama dili değiştiğinde sunucu metinleri ve kullanıcı tercihi birlikte güncellenir.
    func changeLanguage(to newLanguage: AppLanguage) async {
        language.language = newLanguage
        await remoteConfig.load()
        if session.state.user != nil {

            if let updated = try? await user.updateProfile(displayName: nil, timezone: nil, language: newLanguage) {

                session.apply(updated)
            }
        }
    }
}
