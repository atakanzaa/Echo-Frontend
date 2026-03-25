import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var user:         APIUser?
    @Published var isLoading     = false
    @Published var isLoggingOut  = false
    @Published var errorMessage: String?

    private var loadTask:   Task<Void, Never>?
    private var logoutTask: Task<Void, Never>?

    var displayName:    String { user?.displayName ?? user?.email ?? "User" }
    var email:          String { user?.email       ?? "" }
    var totalEntries:   Int    { user?.totalEntries ?? 0 }
    var currentStreak:  Int    { user?.currentStreak ?? 0 }
    var moodAvgText:    String {
        guard let u = user, u.moodScoreAvg > 0 else { return "—" }
        return String(format: "%.1f", u.moodScoreAvg * 10)
    }

    func loadProfile() {
        loadTask?.cancel()
        isLoading    = true
        errorMessage = nil
        loadTask = Task {
            do {
                let u: APIUser = try await APIClient.shared.requestWithAutoRefresh(.me)
                guard !Task.isCancelled else { return }
                user      = u
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func logout() {
        guard !isLoggingOut else { return }
        loadTask?.cancel()
        isLoggingOut = true
        logoutTask = Task {
            let refreshToken = TokenManager.shared.refreshToken() ?? ""
            let body = LogoutBody(refreshToken: refreshToken)
            _ = try? await APIClient.shared.request(.logout(body)) as APIErrorResponse
            TokenManager.shared.clearAll()
            await AppState.shared.signOut()
            isLoggingOut = false
        }
    }
}
