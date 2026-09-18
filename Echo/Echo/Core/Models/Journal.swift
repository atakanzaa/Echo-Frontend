import Foundation
import EchoAPI

/// Günlük kaydı. Analiz bittiğinde `analysis` dolar; durum ve hata kodu sunucudan gelir.
nonisolated struct JournalEntry: Sendable, Equatable, Identifiable {
    let id: String
    let recordedAt: Date
    let entryDay: LocalDay?
    let audioDurationSeconds: Int?
    let transcript: String?
    let status: EchoOperationStatus
    let errorCode: String?
    let analysis: JournalAnalysis?
    let createdAt: Date
    let operationID: String?

    init(dto: Components.Schemas.JournalEntryResponse) {
        id = dto.id
        recordedAt = dto.recordedAt
        entryDay = LocalDay(dto.entryDate)
        audioDurationSeconds = dto.audioDurationSeconds.map(Int.init)
        transcript = dto.transcript
        status = EchoOperationStatus(wire: dto.status.value1?.rawValue ?? dto.status.value2 ?? "")
        errorCode = dto.errorCode.map { $0.value1?.rawValue ?? $0.value2 ?? "" }
        analysis = dto.analysis.map(JournalAnalysis.init(dto:))
        createdAt = dto.createdAt
        operationID = dto.operationId
    }
}

/// Analiz sonucu. Skor ve etiketler sunucu değerleridir; istemci yeniden yorumlamaz.
nonisolated struct JournalAnalysis: Sendable, Equatable {
    let summary: String
    let moodScore: Double
    let moodLabel: String
    let moodCategory: EchoMoodCategory
    let topics: [String]
    let reflectiveQuestion: String
    let keyEmotions: [String]
    let energyLevel: EchoEnergyLevel

    init(dto: Components.Schemas.AnalysisResultResponse) {
        summary = dto.summary
        moodScore = dto.moodScore
        moodLabel = dto.moodLabel
        moodCategory = EchoMoodCategory(wire: dto.moodCategory.value1?.rawValue ?? dto.moodCategory.value2 ?? "")
        topics = dto.topics
        reflectiveQuestion = dto.reflectiveQuestion
        keyEmotions = dto.keyEmotions
        energyLevel = EchoEnergyLevel(wire: dto.energyLevel.value1?.rawValue ?? dto.energyLevel.value2 ?? "")
    }
}

/// Arka plan işinin durumu (rules.md §5). `pollAfterMs`, `terminal` ve `retryable` sunucu kararıdır.
nonisolated struct OperationProgress: Sendable, Equatable, Identifiable {
    let id: String
    let resourceID: String
    let status: EchoOperationStatus
    let stage: EchoOperationStage
    let isTerminal: Bool
    let isRetryable: Bool
    let pollAfterMilliseconds: Int
    let errorCode: String?
    let allowedActions: [EchoAllowedAction]

    init(dto: Components.Schemas.OperationResponse) {
        id = dto.id
        resourceID = dto.resourceId
        status = EchoOperationStatus(wire: dto.status.value1?.rawValue ?? dto.status.value2 ?? "")
        stage = EchoOperationStage(wire: dto.stage.value1?.rawValue ?? dto.stage.value2 ?? "")
        isTerminal = dto.terminal
        isRetryable = dto.retryable
        pollAfterMilliseconds = Int(dto.pollAfterMs)
        errorCode = dto.errorCode.map { $0.value1?.rawValue ?? $0.value2 ?? "" }
        allowedActions = dto.allowedActions.map { EchoAllowedAction(wire: $0.value1?.rawValue ?? $0.value2 ?? "") }
    }

    init(dto: Components.Schemas.JournalStatusResponse) {
        id = dto.operationId ?? dto.id
        resourceID = dto.id
        status = EchoOperationStatus(wire: dto.status.value1?.rawValue ?? dto.status.value2 ?? "")
        stage = EchoOperationStage(wire: dto.stage.value1?.rawValue ?? dto.stage.value2 ?? "")
        isTerminal = dto.terminal
        isRetryable = dto.retryable
        pollAfterMilliseconds = Int(dto.pollAfterMs)
        errorCode = dto.errorCode.map { $0.value1?.rawValue ?? $0.value2 ?? "" }
        allowedActions = []
    }

    var pollInterval: Duration { .milliseconds(max(pollAfterMilliseconds, 500)) }
}

/// Geçmişte bugün kaydı.
nonisolated struct OnThisDayEntry: Sendable, Equatable, Identifiable {
    let id: String
    let day: LocalDay?
    let summary: String
    let moodLabel: String
    let moodScore: Double
    let yearsAgo: Int
}
