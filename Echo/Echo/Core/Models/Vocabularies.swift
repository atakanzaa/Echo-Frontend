import Foundation

/// Sunucu sözlükleri açık enum'dur: bilinen değer tiplenir, bilinmeyen ham metin korunur (rules.md §11).
/// Bilinmeyen değer hiçbir zaman başarı, izin veya yetki anlamına gelmez.

/// Bir işin (journal, coach) sunucudaki durumu.
nonisolated enum EchoOperationStatus: Sendable, Hashable {
    case queued
    case processing
    case retryScheduled
    case succeeded
    case failed
    case cancelled
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "queued": self = .queued
        case "processing": self = .processing
        case "retry_scheduled": self = .retryScheduled
        case "succeeded": self = .succeeded
        case "failed": self = .failed
        case "cancelled": self = .cancelled
        default: self = .unknown(wire)
        }
    }

    var wire: String {
        switch self {
        case .queued: "queued"
        case .processing: "processing"
        case .retryScheduled: "retry_scheduled"
        case .succeeded: "succeeded"
        case .failed: "failed"
        case .cancelled: "cancelled"
        case .unknown(let raw): raw
        }
    }

    /// Yalnız sunucunun terminal dediği durumlar terminaldir; bilinmeyen durum beklemede sayılır.
    var isSucceeded: Bool { self == .succeeded }
}

nonisolated enum EchoOperationStage: Sendable, Hashable {
    case transcription
    case analysis
    case response
    case sessionCreated
    case synthesis
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "transcription": self = .transcription
        case "analysis": self = .analysis
        case "response": self = .response
        case "session_created": self = .sessionCreated
        case "synthesis": self = .synthesis
        default: self = .unknown(wire)
        }
    }
}

/// Sunucunun izin verdiği eylemler; ekran bu listeye bakar, kendi kuralını yazmaz.
nonisolated enum EchoAllowedAction: Sendable, Hashable {
    case viewResult
    case createJournal
    case createCoachSession
    case sendCoachMessage
    case createGoal
    case createCapsule
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "view_result": self = .viewResult
        case "create_journal": self = .createJournal
        case "create_coach_session": self = .createCoachSession
        case "send_coach_message": self = .sendCoachMessage
        case "create_goal": self = .createGoal
        case "create_capsule": self = .createCapsule
        default: self = .unknown(wire)
        }
    }
}

nonisolated enum EchoMoodCategory: Sendable, Hashable {
    case stress
    case neutral
    case calm
    case motivated
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "stress": self = .stress
        case "neutral": self = .neutral
        case "calm": self = .calm
        case "motivated": self = .motivated
        default: self = .unknown(wire)
        }
    }

    var wire: String {
        switch self {
        case .stress: "stress"
        case .neutral: "neutral"
        case .calm: "calm"
        case .motivated: "motivated"
        case .unknown(let raw): raw
        }
    }

    var displayLevel: EchoMoodLevel { EchoMoodLevel(moodCategory: wire) }
}

nonisolated enum EchoEnergyLevel: Sendable, Hashable {
    case low
    case medium
    case high
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        default: self = .unknown(wire)
        }
    }

    var wire: String {
        switch self {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .unknown(let raw): raw
        }
    }
}

nonisolated enum EchoMoodTrend: Sendable, Hashable {
    case improving
    case declining
    case stable
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "improving": self = .improving
        case "declining": self = .declining
        case "stable": self = .stable
        default: self = .unknown(wire)
        }
    }

    var wire: String {
        switch self {
        case .improving: "improving"
        case .declining: "declining"
        case .stable: "stable"
        case .unknown(let raw): raw
        }
    }
}

nonisolated enum EchoGoalStatus: Sendable, Hashable {
    case pending
    case active
    case completed
    case dismissed
    case deleted
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "pending": self = .pending
        case "active": self = .active
        case "completed": self = .completed
        case "dismissed": self = .dismissed
        case "deleted": self = .deleted
        default: self = .unknown(wire)
        }
    }

    var wire: String {
        switch self {
        case .pending: "pending"
        case .active: "active"
        case .completed: "completed"
        case .dismissed: "dismissed"
        case .deleted: "deleted"
        case .unknown(let raw): raw
        }
    }

    var isOpen: Bool { self == .pending || self == .active }
}

nonisolated enum EchoModerationStatus: Sendable, Hashable {
    case visible
    case underReview
    case removed
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "visible": self = .visible
        case "under_review": self = .underReview
        case "removed": self = .removed
        default: self = .unknown(wire)
        }
    }
}

nonisolated enum EchoNotificationTarget: Sendable, Hashable {
    case journalEntry
    case journal
    case achievement
    case post
    case coach
    case insights
    case capsule
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "journal_entry": self = .journalEntry
        case "journal": self = .journal
        case "achievement": self = .achievement
        case "post": self = .post
        case "coach": self = .coach
        case "insights": self = .insights
        case "capsule": self = .capsule
        default: self = .unknown(wire)
        }
    }
}

nonisolated enum EchoCapsuleStatus: Sendable, Hashable {
    case sealed
    case opened
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "sealed": self = .sealed
        case "opened": self = .opened
        default: self = .unknown(wire)
        }
    }
}

nonisolated enum EchoPostContentType: Sendable, Hashable {
    case text
    case image
    case achievement
    case unknown(String)

    init(wire: String) {
        switch wire {
        case "text": self = .text
        case "image": self = .image
        case "achievement": self = .achievement
        default: self = .unknown(wire)
        }
    }
}
