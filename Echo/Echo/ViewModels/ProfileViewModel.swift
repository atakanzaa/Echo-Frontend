import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var user:              APIUser?
    @Published var profileSummary:    APIProfileSummary?
    @Published var isLoading          = false
    @Published var isLoggingOut       = false
    @Published var isUpdatingLanguage = false
    @Published var errorMessage:      String?

    var preferredLanguage: String { LocalizationManager.shared.currentLanguage }

    private var loadTask:   Task<Void, Never>?
    private var logoutTask: Task<Void, Never>?

    var displayName:    String { user?.displayName ?? user?.email ?? "User" }
    var email:          String { user?.email       ?? "" }
    var totalEntries:   Int    { user?.totalEntries ?? 0 }
    var currentStreak:  Int    { user?.currentStreak ?? 0 }

    func loadProfile() {
        loadTask?.cancel()
        isLoading    = true
        errorMessage = nil
        loadTask = Task {
            do {
                async let userReq: APIUser = APIClient.shared.requestWithAutoRefresh(.me)
                async let summaryReq: APIProfileSummary? = loadProfileSummary()

                let (u, s) = try await (userReq, summaryReq)
                guard !Task.isCancelled else { return }
                user            = u
                profileSummary  = s
                isLoading       = false
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func updateLanguage(_ language: String) {
        guard !isUpdatingLanguage else { return }
        isUpdatingLanguage = true
        Task {
            LocalizationManager.shared.currentLanguage = language
            isUpdatingLanguage = false
        }
    }

    func logout() {
        guard !isLoggingOut else { return }
        loadTask?.cancel()
        isLoggingOut = true
        logoutTask = Task {
            if let refreshToken = TokenManager.shared.refreshToken() {
                let body = LogoutBody(refreshToken: refreshToken)
                let _: APIVoidResponse? = try? await APIClient.shared.requestWithAutoRefresh(.logout(body))
            }
            AppState.shared.signOut()
            isLoggingOut = false
        }
    }

    // MARK: - Private helpers

    private func loadProfileSummary() async -> APIProfileSummary? {
        do {
            return try await APIClient.shared.requestWithAutoRefresh(.profileSummary)
        } catch {
            return nil
        }
    }
}
