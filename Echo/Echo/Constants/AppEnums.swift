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
    case help

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

    var displayTitle: String {
        switch self {
        case .queued: return "Queued"
        case .processing: return "Processing"
        case .transcribing: return "Transcribing"
        case .analyzing: return "Analyzing"
        case .complete: return "Complete"
        case .failed: return "Failed"
        case .unknown: return "Processing"
        }
    }
}

enum CommunityTab: String, Codable, CaseIterable {
    case global
    case following

    var title: String {
        switch self {
        case .global: return "Global"
        case .following: return "Following"
        }
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

    var displayTitle: String {
        switch self {
        case .sealed: return "Sealed"
        case .unlocked: return "Unlocked"
        case .opened: return "Opened"
        case .unknown: return "Unknown"
        }
    }
}

enum CapsuleContentType: String, Codable {
    case audio
    case text
    case unknown

    init(rawBackend value: String) {
        self = CapsuleContentType(rawValue: value.lowercased()) ?? .unknown
    }

    var displayTitle: String {
        switch self {
        case .audio: return "Audio"
        case .text: return "Text"
        case .unknown: return "Memory"
        }
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
