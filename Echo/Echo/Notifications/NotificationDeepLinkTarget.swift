import Foundation

enum NotificationDeepLinkTarget: String {
    case journalEntry = "JOURNAL_ENTRY"
    case achievement = "ACHIEVEMENT"
    case post = "POST"
    case capsule = "CAPSULE"
    case insights = "INSIGHTS"
    case coach = "COACH"
    case goal = "GOAL"

    var tab: AppTab {
        switch self {
        case .journalEntry: return .journal
        case .achievement: return .achievements
        case .post: return .community
        case .capsule: return .timeCapsule
        case .insights: return .insights
        case .coach: return .coach
        case .goal: return .goals
        }
    }
}
