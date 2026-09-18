import Foundation
import EchoAPI

/// Abonelik uçları (rules.md §8). Satın alma sonucunu backend doğrular.
nonisolated protocol SubscriptionServicing: Sendable {
    func status() async throws -> SubscriptionStatus
    func products() async throws -> SubscriptionCatalog
    func verify(signedTransaction: String) async throws -> PurchaseResult
    func restore(signedTransaction: String) async throws -> PurchaseResult
    func dismissPaywall() async throws
}

nonisolated struct LiveSubscriptionService: SubscriptionServicing {
    let stack: EchoAPIStack

    func status() async throws -> SubscriptionStatus {
        switch try await stack.client.getSubscriptionStatus(.init()) {
        case .ok(let ok): return SubscriptionStatus(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func products() async throws -> SubscriptionCatalog {
        switch try await stack.client.listSubscriptionProducts(.init()) {
        case .ok(let ok): return SubscriptionCatalog(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func verify(signedTransaction: String) async throws -> PurchaseResult {
        switch try await stack.client.verifyPurchase(.init(body: .json(.init(signedTransaction: signedTransaction)))) {
        case .ok(let ok): return PurchaseResult(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func restore(signedTransaction: String) async throws -> PurchaseResult {
        switch try await stack.client.restorePurchase(.init(body: .json(.init(signedTransaction: signedTransaction)))) {
        case .ok(let ok): return PurchaseResult(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func dismissPaywall() async throws {
        switch try await stack.client.dismissPaywall(.init()) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
