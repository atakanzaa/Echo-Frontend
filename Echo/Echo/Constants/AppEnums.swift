import Foundation

enum AppTab: String, CaseIterable {
    case home
    case community
    case coach
    case profile
    case journal
    case goals
    case calendar
    case insights
    case aiInsights = "aiinsights"
    case achievements
    case timeCapsule = "timecapsule"
    case premium
    case settings
    case notifications
    case notificationList = "notification_list"
    case help
    case aboutApp = "about-app"
    case dataPrivacy = "data-privacy"
    case termsOfUse = "terms-of-use"
    case privacyPolicy = "privacy-policy"
    case acknowledgements
    case aiProfile = "ai-profile"
    case editProfile = "edit-profile"
    case changePassword = "change-password"

    var isPrimaryNavigationTab: Bool {
        switch self {
        case .home, .community, .coach, .profile:
            return true
        default:
            return false
        }
    }
}

enum EntryStatus: String, Codable {
    case queued
    case processing
    case transcribing
    case analyzing
    case complete
    case failed
    case unknown

    init(rawBackend value: String) {
        self = EntryStatus(rawValue: value.lowercased()) ?? .unknown
    }

    var isTerminal: Bool {
        switch self {
        case .complete, .failed:
            return true
        default:
            return false
        }
    }

    var displayTitleKey: String {
        switch self {
        case .queued: return "entry.status.queued"
        case .processing: return "entry.status.processing"
        case .transcribing: return "entry.status.transcribing"
        case .analyzing: return "entry.status.analyzing"
        case .complete: return "entry.status.complete"
        case .failed: return "entry.status.failed"
        case .unknown: return "entry.status.processing"
        }
    }

    var displayTitle: String {
        LocalizationManager.shared.t(displayTitleKey)
    }
}

enum CommunityTab: String, Codable, CaseIterable {
    case global
    case following

    var titleKey: String {
        switch self {
        case .global: return "community.global"
        case .following: return "community.following"
        }
    }

    var title: String {
        LocalizationManager.shared.t(titleKey)
    }
}

enum CapsuleStatus: String, Codable {
    case sealed
    case unlocked
    case opened
    case unknown

    init(rawBackend value: String) {
        self = CapsuleStatus(rawValue: value.lowercased()) ?? .unknown
    }

    var displayTitleKey: String {
        switch self {
        case .sealed: return "capsule.status.sealed"
        case .unlocked: return "capsule.status.unlocked"
        case .opened: return "capsule.status.opened"
        case .unknown: return "capsule.status.unknown"
        }
    }

    var displayTitle: String {
        LocalizationManager.shared.t(displayTitleKey)
    }
}

enum CapsuleContentType: String, Codable {
    case audio
    case text
    case unknown

    init(rawBackend value: String) {
        self = CapsuleContentType(rawValue: value.lowercased()) ?? .unknown
    }

    var displayTitleKey: String {
        switch self {
        case .audio: return "capsule.content.audio"
        case .text: return "capsule.content.text"
        case .unknown: return "capsule.content.memory"
        }
    }

    var displayTitle: String {
        LocalizationManager.shared.t(displayTitleKey)
    }
}

enum PostContentType: String, Codable {
    case text
    case image
    case audio
    case mixed
    case unknown

    init(rawBackend value: String) {
        switch value.lowercased() {
        case "voice":
            self = .audio
        default:
            self = PostContentType(rawValue: value.lowercased()) ?? .unknown
        }
    }
}

enum CoachMessageRole: String, Codable {
    case user
    case assistant
    case system
    case unknown

    init(rawBackend value: String) {
        self = CoachMessageRole(rawValue: value.lowercased()) ?? .unknown
    }
}

enum GoalSuggestionType: String, Codable {
    case createGoal = "CREATE_GOAL"
    case completeGoalConfirm = "COMPLETE_GOAL_CONFIRM"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).uppercased()
        self = GoalSuggestionType(rawValue: raw) ?? .unknown
    }
}

enum GoalSuggestionSourceType: String, Codable {
    case journal = "JOURNAL"
    case coach = "COACH"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).uppercased()
        self = GoalSuggestionSourceType(rawValue: raw) ?? .unknown
    }
}

enum MoodCategory: String, Codable {
    case stress = "STRESS"
    case neutral = "NEUTRAL"
    case calm = "CALM"
    case motivated = "MOTIVATED"
    case unknown

    init(rawBackend value: String) {
        self = MoodCategory(rawValue: value.uppercased()) ?? .unknown
    }
}
