import Foundation
import EchoAPI

/// Public yapılandırma ve sözlük uçları (rules.md §2, §11).
nonisolated protocol AppConfigServicing: Sendable {
    func config(appVersion: String?) async throws -> RemoteAppConfig
    func vocabulary() async throws -> ServerVocabulary
}

nonisolated struct LiveAppConfigService: AppConfigServicing {
    let stack: EchoAPIStack

    func config(appVersion: String?) async throws -> RemoteAppConfig {
        switch try await stack.client.getAppConfig(.init(query: .init(appVersion: appVersion))) {
        case .ok(let ok):
            return RemoteAppConfig(dto: try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func vocabulary() async throws -> ServerVocabulary {
        switch try await stack.client.getAppVocabulary(.init()) {
        case .ok(let ok):
            return ServerVocabulary(dto: try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
