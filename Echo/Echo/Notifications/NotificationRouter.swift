import Foundation

@MainActor
enum NotificationRouter {
    static func route(payload: [AnyHashable: Any]) {
        let targetType = (payload["target_type"] as? String) ?? (payload["targetType"] as? String)
        let resolved = NotificationDeepLinkTarget(rawValue: (targetType ?? "").uppercased())
        let tab = resolved?.tab ?? fallbackTab(forType: payload["type"] as? String)
        NotificationViewModel.shared.pendingNavigation = NotificationNavigation(tab: tab)

        if let notificationId = payload["notification_id"] as? String, !notificationId.isEmpty {
            Task { await NotificationViewModel.shared.markRead(notificationId) }
        }
    }

    private static func fallbackTab(forType type: String?) -> AppTab {
        guard let type = type?.uppercased() else { return .home }
        switch type {
        case "ANALYSIS_COMPLETE": return .journal
        case "ACHIEVEMENT_EARNED": return .achievements
        case "POST_COMMENTED", "POST_LIKED", "COMMENT_REPLIED": return .community
        case "CAPSULE_UNLOCKED": return .timeCapsule
        case "MOOD_ALERT": return .coach
        case "WEEKLY_REFLECTION", "INSIGHT_UNLOCKED": return .insights
        default: return .home
        }
    }
}
