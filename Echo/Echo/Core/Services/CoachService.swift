import Foundation
import EchoAPI

/// Koç uçları (rules.md §7). Mesaj gönderimi 202 döner ve sonuç operation ile poll edilir.
nonisolated protocol CoachServicing: Sendable {
    func sessions(cursor: String?, size: Int) async throws -> ListPage<CoachSession>
    func createSession(journalEntryID: String?, idempotencyKey: String) async throws -> CoachSession
    func messages(sessionID: String, cursor: String?, size: Int) async throws -> ListPage<CoachMessage>
    func sendMessage(sessionID: String, content: String, idempotencyKey: String) async throws -> OperationProgress
    func operation(id: String) async throws -> OperationProgress
    func endSession(id: String) async throws
    func deleteSession(id: String) async throws
}

nonisolated struct LiveCoachService: CoachServicing {
    let stack: EchoAPIStack

    func sessions(cursor: String?, size: Int) async throws -> ListPage<CoachSession> {
        switch try await stack.client.listCoachSessions(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(CoachSession.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func createSession(journalEntryID: String?, idempotencyKey: String) async throws -> CoachSession {
        let input = Operations.CreateCoachSession.Input(headers: .init(idempotencyKey: idempotencyKey),
                                                        body: .json(.init(journalEntryId: journalEntryID)))
        switch try await stack.client.createCoachSession(input) {
        case .created(let created): return CoachSession(dto: try created.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func messages(sessionID: String, cursor: String?, size: Int) async throws -> ListPage<CoachMessage> {
        let input = Operations.ListCoachMessages.Input(path: .init(sessionId: sessionID),
                                                       query: .init(cursor: cursor, size: Int32(size)))
        switch try await stack.client.listCoachMessages(input) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(CoachMessage.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func sendMessage(sessionID: String, content: String, idempotencyKey: String) async throws -> OperationProgress {
        let input = Operations.SendCoachMessage.Input(path: .init(sessionId: sessionID),
                                                       headers: .init(idempotencyKey: idempotencyKey),
                                                       body: .json(.init(content: content)))
        switch try await stack.client.sendCoachMessage(input) {
        case .accepted(let accepted): return OperationProgress(dto: try accepted.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func operation(id: String) async throws -> OperationProgress {
        switch try await stack.client.getOperation(.init(path: .init(id: id))) {
        case .ok(let ok): return OperationProgress(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func endSession(id: String) async throws {
        switch try await stack.client.endCoachSession(.init(path: .init(sessionId: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func deleteSession(id: String) async throws {
        switch try await stack.client.deleteCoachSession(.init(path: .init(sessionId: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
