import Foundation
import Combine

@MainActor
final class GoalViewModel: ObservableObject {

    @Published var activeGoals:  [APIGoal] = []
    @Published var isLoading     = false
    @Published var errorMessage: String?

    func loadActiveGoals() {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let result: [APIGoal] = try await APIClient.shared.requestWithAutoRefresh(.getActiveGoals)
                activeGoals = result
                isLoading   = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func completeGoal(_ goal: APIGoal) {
        Task {
            do {
                let _: APIGoal = try await APIClient.shared.requestWithAutoRefresh(.completeGoal(id: goal.id))
                activeGoals.removeAll { $0.id == goal.id }
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func dismissGoal(_ goal: APIGoal) {
        Task {
            do {
                let _: APIGoal = try await APIClient.shared.requestWithAutoRefresh(.dismissGoal(id: goal.id))
                activeGoals.removeAll { $0.id == goal.id }
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }
}
