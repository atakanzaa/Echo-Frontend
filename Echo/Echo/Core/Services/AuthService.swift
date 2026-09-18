import Foundation
import EchoAPI

/// Kimlik doğrulama uçları (rules.md §2). Token'lar paketin oturum katmanında saklanır.
nonisolated protocol AuthServicing: Sendable {
    func signIn(email: String, password: String) async throws -> AuthenticatedUser
    func register(email: String, password: String, displayName: String, timezone: String, language: AppLanguage) async throws -> AuthenticatedUser
    func signInWithGoogle(idToken: String, timezone: String, language: AppLanguage) async throws -> AuthenticatedUser
    func signInWithApple(identityToken: String, rawNonce: String, displayName: String?, timezone: String, language: AppLanguage) async throws -> AuthenticatedUser
    func currentUser() async throws -> AuthenticatedUser
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func changePassword(currentPassword: String, newPassword: String) async throws -> AuthenticatedUser
    func signOut() async throws
}

nonisolated struct LiveAuthService: AuthServicing {
    let stack: EchoAPIStack

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        switch try await stack.client.login(.init(body: .json(.init(email: email, password: password)))) {
        case .ok(let ok):
            return try await store(try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func register(email: String, password: String, displayName: String, timezone: String, language: AppLanguage) async throws -> AuthenticatedUser {
        let body = Components.Schemas.RegisterRequest(email: email, password: password, displayName: displayName,
                                                      timezone: timezone, language: .init(rawValue: language.rawValue))
        switch try await stack.client.register(.init(body: .json(body))) {
        case .created(let created):
            return try await store(try created.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func signInWithGoogle(idToken: String, timezone: String, language: AppLanguage) async throws -> AuthenticatedUser {
        let body = Components.Schemas.GoogleLoginRequest(idToken: idToken, timezone: timezone,
                                                         language: .init(rawValue: language.rawValue))
        switch try await stack.client.loginWithGoogle(.init(body: .json(body))) {
        case .ok(let ok):
            return try await store(try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func signInWithApple(identityToken: String, rawNonce: String, displayName: String?, timezone: String, language: AppLanguage) async throws -> AuthenticatedUser {
        let body = Components.Schemas.AppleLoginRequest(identityToken: identityToken, rawNonce: rawNonce,
                                                        displayName: displayName, timezone: timezone,
                                                        language: .init(rawValue: language.rawValue))
        switch try await stack.client.loginWithApple(.init(body: .json(body))) {
        case .ok(let ok):
            return try await store(try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func currentUser() async throws -> AuthenticatedUser {
        switch try await stack.client.getCurrentUser(.init()) {
        case .ok(let ok):
            return AuthenticatedUser(dto: try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func requestPasswordReset(email: String) async throws {
        switch try await stack.client.forgotPassword(.init(body: .json(.init(email: email)))) {
        case .ok:
            return
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let body = Components.Schemas.ResetPasswordRequest(email: email, code: code, newPassword: newPassword)
        switch try await stack.client.resetPassword(.init(body: .json(body))) {
        case .noContent:
            return
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws -> AuthenticatedUser {
        let body = Components.Schemas.ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
        switch try await stack.client.changePassword(.init(body: .json(body))) {
        case .ok(let ok):
            return try await store(try ok.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    /// Sunucudaki refresh oturumunu kapatır; yerel temizlik tek başına yeterli değildir.
    func signOut() async throws {
        if let refreshToken = try? stack.tokenStore.read()?.refreshToken {

            let body = Components.Schemas.RefreshTokenRequest(refreshToken: refreshToken)
            _ = try? await stack.client.logout(.init(body: .json(body)))
        }
        try await stack.session.replace(with: nil)
    }

    private func store(_ auth: Components.Schemas.AuthResponse) async throws -> AuthenticatedUser {
        try await stack.session.replace(with: SessionTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken))
        return AuthenticatedUser(dto: auth.user)
    }
}
