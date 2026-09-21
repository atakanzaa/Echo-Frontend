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
                    user: LiveUserService(stack: stack))
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

    let session: SessionStore
    let remoteConfig: AppConfigStore
    let pendingJournals: PendingJournalStore
    let submissions: JournalSubmissionStore
    let network = NetworkStatus()

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

        session = SessionStore(auth: services.auth, notifications: services.notifications, tokenStore: stack.tokenStore)
        remoteConfig = AppConfigStore(service: services.appConfig,
                                      appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        let pendingJournals = PendingJournalStore()
        self.pendingJournals = pendingJournals
        submissions = JournalSubmissionStore(journal: services.journal, pending: pendingJournals)
    }

    /// Sunucu adresi ve Keychain servisi Info.plist'ten gelir; adres kodda uydurulmaz.
    static func make() throws -> AppEnvironment {
        let configuration = try AppConfiguration.load()
        let language = AppLanguageStore()
        let stack = try EchoAPIStack.make(serverURL: configuration.apiBaseURL,
                                          keychainService: configuration.keychainService,
                                          language: language.headerProvider)
        return AppEnvironment(configuration: configuration, stack: stack, language: language)
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
