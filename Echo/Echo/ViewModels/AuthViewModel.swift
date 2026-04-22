import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = APIClient.shared
    private let appState = AppState.shared

    // MARK: - Register

    func register(email: String, password: String, displayName: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let timezone = TimeZone.current.identifier
        let body = RegisterBody(
            email: email,
            password: password,
            displayName: displayName,
            timezone: timezone
        )

        do {
            let response: APIAuthResponse = try await client.request(.register(body))
            appState.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let body = LoginBody(email: email, password: password)

        do {
            let response: APIAuthResponse = try await client.request(.login(body))
            appState.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Password reset

    func forgotPassword(email: String) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let _: APIVoidResponse = try await client.request(.forgotPassword(ForgotPasswordBody(email: email)))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func resetPassword(email: String, code: String, newPassword: String) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let body = ResetPasswordBody(email: email, code: code, newPassword: newPassword)
            let _: APIVoidResponse = try await client.request(.resetPassword(body))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let body = ChangePasswordBody(currentPassword: currentPassword, newPassword: newPassword)
            let response: APIAuthResponse = try await client.requestWithAutoRefresh(.changePassword(body))
            appState.signIn(with: response)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Google Login

    func loginWithGoogle() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let idToken = try await GoogleSignInManager.shared.signInAndGetIdToken()
            let body = GoogleLoginBody(
                idToken: idToken,
                timezone: TimeZone.current.identifier,
                language: LocalizationManager.shared.currentLanguage
            )
            let response: APIAuthResponse = try await client.request(.googleLogin(body))
            appState.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Apple Login

    func loginWithApple() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let appleResult = try await AppleSignInManager.shared.signIn()
            let body = AppleLoginBody(
                identityToken: appleResult.identityToken,
                authorizationCode: appleResult.authorizationCode,
                displayName: appleResult.displayName,
                timezone: TimeZone.current.identifier,
                language: LocalizationManager.shared.currentLanguage
            )
            let response: APIAuthResponse = try await client.request(.appleLogin(body))
            appState.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
