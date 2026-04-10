import Foundation
import Combine

@MainActor
final class GoalViewModel: ObservableObject {

    @Published private(set) var allGoals: [APIGoal] = []
    @Published var journalSuggestions: [APIGoalSuggestion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let loadTask = TaskGuard()
    private let suggestionTask = TaskGuard()
    private let mutationGuard = MutationGuard()

    var activeGoals: [APIGoal] {
        allGoals.filter { ["PENDING", "ACTIVE"].contains($0.status.uppercased()) }
    }

    var historyGoals: [APIGoal] {
        allGoals.filter { ["COMPLETED", "DISMISSED"].contains($0.status.uppercased()) }
    }

    func loadGoals() {
        loadTask.run { [weak self] in
            await self?.performLoadGoals()
        }
    }

    func loadJournalSuggestions(entryId: String) {
        suggestionTask.run { [weak self] in
            await self?.performLoadJournalSuggestions(entryId: entryId)
        }
    }

    func acceptSuggestion(_ suggestion: APIGoalSuggestion) {
        guard mutationGuard.start(id: suggestion.id) else { return }
        Task {
            defer { mutationGuard.finish(id: suggestion.id) }
            do {
                let goal: APIGoal = try await APIClient.shared.requestWithAutoRefresh(.acceptGoalSuggestion(id: suggestion.id))
                journalSuggestions.removeAll { $0.id == suggestion.id }
                successMessage = localizedGoalMessage("goal.success.added", title: goal.title)
                await refresh()
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func rejectSuggestion(_ suggestion: APIGoalSuggestion) {
        guard mutationGuard.start(id: suggestion.id) else { return }
        Task {
            defer { mutationGuard.finish(id: suggestion.id) }
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.rejectGoalSuggestion(id: suggestion.id))
                journalSuggestions.removeAll { $0.id == suggestion.id }
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func completeGoal(_ goal: APIGoal) {
        mutateGoal(goal.id) {
            let _: APIGoal = try await APIClient.shared.requestWithAutoRefresh(.completeGoal(id: goal.id))
            self.successMessage = self.localizedGoalMessage("goal.success.completed", title: goal.title)
            await self.refresh()
        }
    }

    func markNotCompleted(_ goal: APIGoal) {
        mutateGoal(goal.id) {
            let _: APIGoal = try await APIClient.shared.requestWithAutoRefresh(.notCompletedGoal(id: goal.id))
            self.successMessage = self.localizedGoalMessage("goal.success.not_completed", title: goal.title)
            await self.refresh()
        }
    }

    func dismissGoal(_ goal: APIGoal) {
        markNotCompleted(goal)
    }

    func deleteGoal(_ goal: APIGoal) {
        mutateGoal(goal.id) {
            let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.deleteGoal(id: goal.id))
            self.allGoals.removeAll { $0.id == goal.id }
            self.successMessage = self.localizedGoalMessage("goal.success.deleted", title: goal.title)
        }
    }

    func isInFlight(goalId: String) -> Bool {
        mutationGuard.isInFlight(id: goalId)
    }

    func refresh() async {
        await loadTask.runAsync { [weak self] in
            await self?.performLoadGoals()
        }
    }

    func cancelAll() {
        loadTask.cancel()
        suggestionTask.cancel()
        mutationGuard.reset()
    }

    private func performLoadGoals() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [APIGoal] = try await APIClient.shared.requestWithAutoRefresh(.getAllGoals)
            allGoals = result
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }

    private func performLoadJournalSuggestions(entryId: String) async {
        do {
            let result: [APIGoalSuggestion] = try await APIClient.shared.requestWithAutoRefresh(
                .getGoalSuggestions(sourceType: "JOURNAL", journalEntryId: entryId, sessionId: nil)
            )
            journalSuggestions = result
        } catch is CancellationError {
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    private func localizedGoalMessage(_ key: String, title: String) -> String {
        LocalizationManager.shared.t(key, title)
    }

    private func mutateGoal(_ id: String, operation: @escaping @MainActor () async throws -> Void) {
        guard mutationGuard.start(id: id) else { return }
        Task {
            defer { mutationGuard.finish(id: id) }
            do {
                try await operation()
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }
}
