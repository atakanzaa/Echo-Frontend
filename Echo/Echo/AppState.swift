import Foundation
import Combine
import OSLog
import SwiftUI

@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: APIUser?
    @Published var isRestoringSession: Bool = false

    private init() {
        isAuthenticated = TokenManager.shared.hasTokens
        if isAuthenticated {
            isRestoringSession = true
            Task { await validateSession() }
        }
    }

    func validateSession() async {
        isRestoringSession = true
        do {
            let user: APIUser = try await APIClient.shared.requestWithAutoRefresh(.me)
            currentUser = user
        } catch {
            signOut()
        }
        isRestoringSession = false
    }

    func signIn(with authResponse: APIAuthResponse) {
        do {
            try TokenManager.shared.saveAccessToken(authResponse.accessToken)
            try TokenManager.shared.saveRefreshToken(authResponse.refreshToken)
            currentUser       = authResponse.user
            isAuthenticated   = true
            isRestoringSession = false
            Log.auth.info("User session restored successfully")
        } catch {
            Log.auth.error("Token persistence failed: \(error.localizedDescription)")
        }
    }

    func signOut() {
        TokenManager.shared.clearAll()
        currentUser     = nil
        isAuthenticated = false
        isRestoringSession = false
        Log.auth.info("User signed out")
    }
}
