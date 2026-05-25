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
        allGoals.filter { $0.status.isOpen }
    }

    var historyGoals: [APIGoal] {
        allGoals.filter { $0.status.isHistory }
    }

    var completedGoals: [APIGoal] {
        allGoals.filter { $0.status == .completed }
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

    func createGoal(title: String, timeframe: String?) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTimeframe = timeframe?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            errorMessage = LocalizationManager.shared.t("goals.manual_validation")
            return
        }

        let mutationId = "create-goal"
        guard mutationGuard.start(id: mutationId) else { return }
        Task {
            defer { mutationGuard.finish(id: mutationId) }
            do {
                let created: APIGoal = try await APIClient.shared.requestWithAutoRefresh(
                    .createGoal(CreateGoalBody(
                        title: normalizedTitle,
                        timeframe: normalizedTimeframe?.isEmpty == true ? nil : normalizedTimeframe
                    ))
                )
                successMessage = localizedGoalMessage("goal.success.added", title: created.title)
                await refresh()
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
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
        mutateGoal(goal.id) {
            let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.dismissGoal(id: goal.id))
            self.successMessage = self.localizedGoalMessage("goal.success.dismissed", title: goal.title)
            await self.refresh()
        }
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

    func isCreateInFlight() -> Bool {
        mutationGuard.isInFlight(id: "create-goal")
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
            let result: APIPagedResponse<APIGoal> = try await APIClient.shared.requestWithAutoRefresh(.getAllGoals)
            allGoals = result.content
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
