import Foundation
import EchoAPI

/// AI kullanım hakkı ucu (rules.md §8).
nonisolated protocol UsageServicing: Sendable {
    func usage() async throws -> AIUsage
}

nonisolated struct LiveUsageService: UsageServicing {
    let stack: EchoAPIStack

    func usage() async throws -> AIUsage {
        switch try await stack.client.getAiUsage(.init()) {
        case .ok(let ok): return AIUsage(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
