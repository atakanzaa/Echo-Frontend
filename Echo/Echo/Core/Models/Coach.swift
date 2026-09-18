import Foundation
import EchoAPI

/// Koç oturumu. `title` sunucudan gösterime hazır ve yerelleştirilmiş gelir.
nonisolated struct CoachSession: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let startedAt: Date
    let updatedAt: Date
    let isActive: Bool
    let journalEntryID: String?

    init(dto: Components.Schemas.CoachSessionResponse) {
        id = dto.id
        title = dto.title
        startedAt = dto.startedAt
        updatedAt = dto.updatedAt
        isActive = dto.isActive
        journalEntryID = dto.journalEntryId
    }
}

/// Koç mesajı. Yanıt beklenirken `status` işin durumunu taşır.
nonisolated struct CoachMessage: Sendable, Equatable, Identifiable {
    let id: String
    let role: Role
    let content: String
    let createdAt: Date
    let operationID: String?
    let status: EchoOperationStatus

    nonisolated enum Role: Sendable, Equatable {
        case user
        case assistant
        case system
        case unknown(String)

        init(wire: String) {
            switch wire {
            case "user": self = .user
            case "assistant": self = .assistant
            case "system": self = .system
            default: self = .unknown(wire)
            }
        }
    }

    init(dto: Components.Schemas.CoachMessageResponse) {
        id = dto.id
        role = Role(wire: dto.role.value1?.rawValue ?? dto.role.value2 ?? "")
        content = dto.content
        createdAt = dto.createdAt
        operationID = dto.operationId
        status = EchoOperationStatus(wire: dto.status.value1?.rawValue ?? dto.status.value2 ?? "")
    }
}
