import SwiftUI
import Observation

/// Sekme içi yönlendirme hedefleri. Ekranlar sonraki fazlarda bağlanır; hedefler kimliklerle taşınır.
nonisolated enum AppDestination: Hashable, Sendable {
    case journalEntry(id: String)
    case journalSearch
    case insights
    case moodTracker(periodDays: Int)
    case goals
    case createGoal
    case achievements
    case achievementDetail(badgeKey: String)
    case capsules
    case createCapsule
    case capsule(id: String)
    case coachSessions
    case notifications
    case communityPost(id: String)
    case settings
    case editProfile
    case privacyConsent
    case notificationSettings
    case subscription
    case usage
    case blockedAuthors
}

/// Modal sunumlar.
nonisolated enum AppSheet: Identifiable, Hashable, Sendable {
    /// `prompt` günün sorusundan gelir ve kayıt ekranında gösterilir; sözleşmede sunucuya taşıyan alan yok.
    case recording(prompt: String? = nil, sourceEntryID: String? = nil)
    case composer
    case coachChat(sessionId: String?)
    case composePost(prefilledText: String?)
    case paywall

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }

    var id: String {
        switch self {
        case .recording: "recording"
        case .composer: "composer"
        case .coachChat(let sessionId): "coach-\(sessionId ?? "new")"
        case .composePost: "compose-post"
        case .paywall: "paywall"
        }
    }
}

/// Sekme yığınları ve modal durumu tek yerde tutulur; ekranlar birbirini doğrudan sunmaz.
@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .today
    var sheet: AppSheet?
    var paths: [AppTab: NavigationPath] = [:]

    func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(get: { self.paths[tab] ?? NavigationPath() },
                set: { self.paths[tab] = $0 })
    }

    func push(_ destination: AppDestination, on tab: AppTab? = nil) {
        let target = tab ?? selectedTab
        selectedTab = target
        var path = paths[target] ?? NavigationPath()
        path.append(destination)
        paths[target] = path
    }

    /// Aynı sekmeye tekrar dokunmak yığını köke döndürür.
    func popToRoot(_ tab: AppTab) {
        paths[tab] = NavigationPath()
    }

    func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }

    /// Bildirim hedefini ilgili ekrana çevirir; uygulama içi liste ve push aynı yolu kullanır.
    func open(_ target: EchoNotificationTarget, id: String?) {
        switch target {
        case .journalEntry:
            if let id { push(.journalEntry(id: id)) }
        case .journal: selectedTab = .journal
        case .achievement:
            if let id { push(.achievementDetail(badgeKey: id)) } else { push(.achievements) }
        case .post:
            if let id { push(.communityPost(id: id), on: .community) }
        case .coach: present(.coachChat(sessionId: id))
        case .insights: push(.insights)
        case .capsule:
            if let id { push(.capsule(id: id)) } else { push(.capsules) }
        case .adminAlert, .unknown: break
        }
    }
}
