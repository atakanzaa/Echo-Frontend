import Foundation
import EchoAPI

/// Hedef uçları (rules.md §7).
nonisolated protocol GoalServicing: Sendable {
    func activeGoals(cursor: String?, size: Int) async throws -> ListPage<Goal>
    func allGoals(cursor: String?, size: Int) async throws -> ListPage<Goal>
    func stats() async throws -> GoalStats
    func create(title: String, timeframe: String?, idempotencyKey: String) async throws -> Goal
    func complete(id: String) async throws -> Goal
    func markNotCompleted(id: String) async throws -> Goal
    func dismiss(id: String) async throws -> Goal
    func delete(id: String) async throws
    func suggestions(sourceType: String?, suggestionType: String?, journalEntryID: String?, coachSessionID: String?) async throws -> [GoalSuggestion]
    func acceptSuggestion(id: String) async throws -> Goal
    func rejectSuggestion(id: String) async throws
}

nonisolated struct LiveGoalService: GoalServicing {
    let stack: EchoAPIStack

    func activeGoals(cursor: String?, size: Int) async throws -> ListPage<Goal> {
        switch try await stack.client.listActiveGoals(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(Goal.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func allGoals(cursor: String?, size: Int) async throws -> ListPage<Goal> {
        switch try await stack.client.listGoals(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(Goal.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func stats() async throws -> GoalStats {
        switch try await stack.client.getGoalStats(.init()) {
        case .ok(let ok): return GoalStats(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func create(title: String, timeframe: String?, idempotencyKey: String) async throws -> Goal {
        let input = Operations.CreateGoal.Input(headers: .init(idempotencyKey: idempotencyKey),
                                                body: .json(.init(title: title, timeframe: timeframe)))
        switch try await stack.client.createGoal(input) {
        case .created(let created): return Goal(dto: try created.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func complete(id: String) async throws -> Goal {
        switch try await stack.client.completeGoal(.init(path: .init(id: id))) {
        case .ok(let ok): return Goal(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func markNotCompleted(id: String) async throws -> Goal {
        switch try await stack.client.markGoalNotCompleted(.init(path: .init(id: id))) {
        case .ok(let ok): return Goal(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func dismiss(id: String) async throws -> Goal {
        switch try await stack.client.dismissGoal(.init(path: .init(id: id))) {
        case .ok(let ok): return Goal(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func delete(id: String) async throws {
        switch try await stack.client.deleteGoal(.init(path: .init(id: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func suggestions(sourceType: String?, suggestionType: String?, journalEntryID: String?, coachSessionID: String?) async throws -> [GoalSuggestion] {
        let query = Operations.ListGoalSuggestions.Input.Query(sourceType: sourceType.flatMap { .init(rawValue: $0) },
                                                              suggestionType: suggestionType.flatMap { .init(rawValue: $0) },
                                                              journalEntryId: journalEntryID,
                                                              coachSessionId: coachSessionID)
        switch try await stack.client.listGoalSuggestions(.init(query: query)) {
        case .ok(let ok): return try ok.body.json.map(GoalSuggestion.init(dto:))
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func acceptSuggestion(id: String) async throws -> Goal {
        switch try await stack.client.acceptGoalSuggestion(.init(path: .init(id: id))) {
        case .ok(let ok): return Goal(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func rejectSuggestion(id: String) async throws {
        switch try await stack.client.rejectGoalSuggestion(.init(path: .init(id: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
