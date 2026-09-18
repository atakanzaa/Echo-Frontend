import Foundation
import EchoAPI

/// Profil ve gizlilik uçları (rules.md §9).
nonisolated protocol UserServicing: Sendable {
    func updateProfile(displayName: String?, timezone: String?, language: AppLanguage?) async throws -> AuthenticatedUser
    func consent() async throws -> ConsentStatus
    func updateConsent(aiTraining: Bool?, kvkk: Bool?, communityTerms: Bool?) async throws -> ConsentStatus
    /// Hesap silme 202 döner; erişim kapanır, yerel veri çağıran tarafta temizlenir.
    func requestAccountDeletion(appleAuthorizationCode: String?) async throws
}

nonisolated struct LiveUserService: UserServicing {
    let stack: EchoAPIStack

    func updateProfile(displayName: String?, timezone: String?, language: AppLanguage?) async throws -> AuthenticatedUser {
        let body = Components.Schemas.UpdateProfileRequest(displayName: displayName, timezone: timezone,
                                                           language: language.flatMap { .init(rawValue: $0.rawValue) })
        switch try await stack.client.updateProfile(.init(body: .json(body))) {
        case .ok(let ok): return AuthenticatedUser(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func consent() async throws -> ConsentStatus {
        switch try await stack.client.getConsent(.init()) {
        case .ok(let ok): return ConsentStatus(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func updateConsent(aiTraining: Bool?, kvkk: Bool?, communityTerms: Bool?) async throws -> ConsentStatus {
        let body = Components.Schemas.UpdateConsentRequest(aiTrainingConsent: aiTraining,
                                                           kvkkExplicitConsent: kvkk,
                                                           communityTermsAccepted: communityTerms)
        switch try await stack.client.updateConsent(.init(body: .json(body))) {
        case .ok(let ok): return ConsentStatus(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func requestAccountDeletion(appleAuthorizationCode: String?) async throws {
        let body = Components.Schemas.AccountDeletionRequest(appleAuthorizationCode: appleAuthorizationCode)
        switch try await stack.client.requestAccountDeletion(.init(body: .json(body))) {
        case .accepted: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
