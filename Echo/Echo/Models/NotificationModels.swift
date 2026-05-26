import Foundation

struct AppNotification: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let tab: String
    let createdAt: Date
    var isRead: Bool

    init(from api: APINotificationItem) {
        id = api.id
        title = api.title
        body = api.body
        tab = Self.resolveTab(type: api.type, targetType: api.targetType)
        createdAt = Self.parseDate(api.createdAt)
        isRead = api.isRead
    }

    private static func resolveTab(type: String, targetType: String?) -> String {
        let normalizedTarget = targetType?.uppercased()
        switch normalizedTarget {
        case "JOURNAL_ENTRY":
            return "journal"
        case "ACHIEVEMENT":
            return "achievements"
        case "POST":
            return "community"
        case "CAPSULE":
            return "timecapsule"
        default:
            break
        }

        switch type.uppercased() {
        case "ANALYSIS_COMPLETE":
            return "journal"
        case "ACHIEVEMENT_EARNED":
            return "achievements"
        case "POST_COMMENTED", "POST_LIKED", "COMMENT_REPLIED":
            return "community"
        case "CAPSULE_UNLOCKED":
            return "timecapsule"
        case "MOOD_ALERT":
            return "coach"
        case "INSIGHT_UNLOCKED", "WEEKLY_REFLECTION":
            return "insights"
        default:
            return "home"
        }
    }

    private static func parseDate(_ value: String?) -> Date {
        guard let value, !value.isEmpty else { return Date() }
        return DateFormatting.parseISO8601(value) ?? Date()
    }
}

struct NotificationNavigation: Identifiable {
    let id = UUID()
    let tab: String
}

struct APINotificationItem: Decodable {
    let id: String
    let type: String
    let title: String
    let body: String
    let groupKey: String?
    let targetType: String?
    let targetId: String?
    let isRead: Bool
    let createdAt: String?
    let readAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body
        case groupKey
        case targetType
        case targetId
        case isRead
        case read
        case createdAt
        case readAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        groupKey = try container.decodeIfPresent(String.self, forKey: .groupKey)
        targetType = try container.decodeIfPresent(String.self, forKey: .targetType)
        targetId = try container.decodeIfPresent(String.self, forKey: .targetId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        readAt = try container.decodeIfPresent(String.self, forKey: .readAt)

        if let explicit = try container.decodeIfPresent(Bool.self, forKey: .isRead) {
            isRead = explicit
        } else if let legacy = try container.decodeIfPresent(Bool.self, forKey: .read) {
            isRead = legacy
        } else {
            isRead = false
        }
    }
}

struct APIUnreadCountResponse: Decodable {
    let count: Int
}
