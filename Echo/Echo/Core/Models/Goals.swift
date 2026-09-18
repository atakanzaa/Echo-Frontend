import Foundation
import EchoAPI

/// Hedef. Tamamlanma tespiti ve durum değişimi sunucu kararıdır.
nonisolated struct Goal: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let timeframe: String?
    let goalType: String?
    let creationType: String
    let status: EchoGoalStatus
    let sourceJournalEntryID: String?
    let detectedAt: Date
    let completedAt: Date?
    let completionType: String?

    init(dto: Components.Schemas.GoalResponse) {
        id = dto.id
        title = dto.title
        timeframe = dto.timeframe
        goalType = dto.goalType
        creationType = dto.creationType.value1?.rawValue ?? dto.creationType.value2 ?? ""
        status = EchoGoalStatus(wire: dto.status.value1?.rawValue ?? dto.status.value2 ?? "")
        sourceJournalEntryID = dto.sourceJournalEntryId
        detectedAt = dto.detectedAt
        completedAt = dto.completedAt
        completionType = dto.completionType.map { $0.value1?.rawValue ?? $0.value2 ?? "" }
    }
}

/// Hedef önerisi. Buton metinleri sunucudan gelir.
nonisolated struct GoalSuggestion: Sendable, Equatable, Identifiable {
    let id: String
    let goalID: String?
    let suggestionType: String
    let sourceType: String
    let title: String?
    let timeframe: String?
    let detectedText: String?
    let reason: String?
    let confidence: Double?
    let message: String
    let primaryActionLabel: String
    let secondaryActionLabel: String
    let createdAt: Date
    let expiresAt: Date?

    init(dto: Components.Schemas.GoalSuggestionResponse) {
        id = dto.id
        goalID = dto.goalId
        suggestionType = dto.suggestionType.value1?.rawValue ?? dto.suggestionType.value2 ?? ""
        sourceType = dto.sourceType.value1?.rawValue ?? dto.sourceType.value2 ?? ""
        title = dto.title
        timeframe = dto.timeframe
        detectedText = dto.detectedText
        reason = dto.reason
        confidence = dto.confidence
        message = dto.message
        primaryActionLabel = dto.primaryActionLabel
        secondaryActionLabel = dto.secondaryActionLabel
        createdAt = dto.createdAt
        expiresAt = dto.expiresAt
    }
}

/// Hedef sayaçları; istemci listeyi sayarak üretmez (rules.md §7).
nonisolated struct GoalStats: Sendable, Equatable {
    let activeCount: Int
    let completedCount: Int
    let dismissedCount: Int
    let completedThisWeek: Int
    let weekStart: LocalDay?

    init(dto: Components.Schemas.GoalStatsResponse) {
        activeCount = Int(dto.activeCount)
        completedCount = Int(dto.completedCount)
        dismissedCount = Int(dto.dismissedCount)
        completedThisWeek = Int(dto.completedThisWeek)
        weekStart = LocalDay(dto.weekStart)
    }
}
