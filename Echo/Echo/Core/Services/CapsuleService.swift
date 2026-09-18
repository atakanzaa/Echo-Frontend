import Foundation
import EchoAPI

/// Kapsül uçları (rules.md §6).
nonisolated protocol CapsuleServicing: Sendable {
    func list(cursor: String?, size: Int) async throws -> ListPage<TimeCapsule>
    func summary() async throws -> CapsuleSummary
    func create(title: String?, text: String, unlockAt: Date, idempotencyKey: String) async throws -> TimeCapsule
    func capsule(id: String) async throws -> TimeCapsule
    func open(id: String) async throws -> TimeCapsule
    func delete(id: String) async throws
}

nonisolated struct LiveCapsuleService: CapsuleServicing {
    let stack: EchoAPIStack

    func list(cursor: String?, size: Int) async throws -> ListPage<TimeCapsule> {
        switch try await stack.client.listCapsules(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(TimeCapsule.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func summary() async throws -> CapsuleSummary {
        switch try await stack.client.getCapsuleSummary(.init()) {
        case .ok(let ok): return CapsuleSummary(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func create(title: String?, text: String, unlockAt: Date, idempotencyKey: String) async throws -> TimeCapsule {
        let body = Components.Schemas.CreateCapsuleRequest(title: title, contentText: text, contentType: .text, unlockAt: unlockAt)
        switch try await stack.client.createCapsule(.init(headers: .init(idempotencyKey: idempotencyKey), body: .json(body))) {
        case .created(let created): return TimeCapsule(dto: try created.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func capsule(id: String) async throws -> TimeCapsule {
        switch try await stack.client.getCapsule(.init(path: .init(id: id))) {
        case .ok(let ok): return TimeCapsule(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func open(id: String) async throws -> TimeCapsule {
        switch try await stack.client.openCapsule(.init(path: .init(id: id))) {
        case .ok(let ok): return TimeCapsule(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func delete(id: String) async throws {
        switch try await stack.client.deleteCapsule(.init(path: .init(id: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
