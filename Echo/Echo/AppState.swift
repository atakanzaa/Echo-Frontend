import Foundation
import Combine
import OSLog
import SwiftUI

/// Uygulama genelinde auth durumunu tutar.
/// APIClient'tan da erişilebilmesi için singleton + @MainActor.
@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: APIUser?
    @Published var isRestoringSession: Bool = false

    private init() {
        // Uygulama açılışında token varsa otomatik login
        isAuthenticated = TokenManager.shared.hasTokens
        if isAuthenticated {
            isRestoringSession = true
            Task { await validateSession() }
        }
    }

    /// Keychain'deki token'ları backend'e doğrulayıp currentUser'ı restore eder.
    /// Token geçersizse (süresi dolmuş, backend yeniden başlamış vb.) oturumu kapatır.
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
        // Unregister the push token before clearing auth so the backend can
        // call DELETE /push-token while we still have valid credentials. We
        // detach into a Task so signOut() stays synchronous; if the request
        // fails (e.g. offline), the worst case is a stale row server-side
        // that APNs feedback will eventually invalidate.
        Task { @MainActor in
            await PushNotificationManager.shared.unregisterCurrentTokenIfPossible()
            TokenManager.shared.clearAll()
            self.currentUser     = nil
            self.isAuthenticated = false
            self.isRestoringSession = false
            Log.auth.info("User signed out")
        }
    }
}
