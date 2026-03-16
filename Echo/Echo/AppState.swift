import Foundation
import Combine
import SwiftUI

/// Uygulama genelinde auth durumunu tutar.
/// APIClient'tan da erişilebilmesi için singleton + @MainActor.
@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: APIUser?

    private init() {
        // Uygulama açılışında token varsa otomatik login
        isAuthenticated = TokenManager.shared.hasTokens
        if isAuthenticated {
            Task { await validateSession() }
        }
    }

    /// Keychain'deki token'ları backend'e doğrulayıp currentUser'ı restore eder.
    /// Token geçersizse (süresi dolmuş, backend yeniden başlamış vb.) oturumu kapatır.
    func validateSession() async {
        do {
            let user: APIUser = try await APIClient.shared.requestWithAutoRefresh(.me)
            currentUser = user
        } catch {
            signOut()
        }
    }

    func signIn(with authResponse: APIAuthResponse) {
        do {
            try TokenManager.shared.saveAccessToken(authResponse.accessToken)
            try TokenManager.shared.saveRefreshToken(authResponse.refreshToken)
            currentUser       = authResponse.user
            isAuthenticated   = true
        } catch {
            print("Token kaydedilemedi: \(error.localizedDescription)")
        }
    }

    func signOut() {
        TokenManager.shared.clearAll()
        currentUser     = nil
        isAuthenticated = false
    }
}
