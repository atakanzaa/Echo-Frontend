import Foundation
import EchoAPI

/// Zaman kapsülü. `canOpen` sunucu kararıdır; istemci `unlockAt` karşılaştırmasıyla izin üretmez.
nonisolated struct TimeCapsule: Sendable, Equatable, Identifiable {
    let id: String
    let title: String?
    let contentText: String?
    let status: EchoCapsuleStatus
    let sealedAt: Date
    let unlockAt: Date
    let openedAt: Date?
    let canOpen: Bool

    init(dto: Components.Schemas.TimeCapsuleResponse) {
        id = dto.id
        title = dto.title
        contentText = dto.contentText
        status = EchoCapsuleStatus(wire: dto.status.value1?.rawValue ?? dto.status.value2 ?? "")
        sealedAt = dto.sealedAt
        unlockAt = dto.unlockAt
        openedAt = dto.openedAt
        canOpen = dto.canOpen
    }
}

/// Kapsül sayaçları ve sıradaki açılış (rules.md §6).
nonisolated struct CapsuleSummary: Sendable, Equatable {
    let sealedCount: Int
    let openedCount: Int
    let openableCount: Int
    let nextCapsuleID: String?
    let nextUnlockAt: Date?

    init(dto: Components.Schemas.CapsuleSummaryResponse) {
        sealedCount = Int(dto.sealedCount)
        openedCount = Int(dto.openedCount)
        openableCount = Int(dto.openableCount)
        nextCapsuleID = dto.nextCapsuleId
        nextUnlockAt = dto.nextUnlockAt
    }
}
