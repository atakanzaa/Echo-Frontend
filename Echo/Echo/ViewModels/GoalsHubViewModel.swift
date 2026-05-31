import Foundation
import Combine

@MainActor
final class GoalsHubViewModel: ObservableObject {

    @Published var manualTitle = ""
    @Published var manualTimeframe = ""
    @Published private(set) var activeGoals: [APIGoal] = []
    @Published private(set) var completedGoals: [APIGoal] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isCreating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published private(set) var aiSuggestions: [APIGoalSuggestion] = []
    @Published private(set) var inFlightSuggestionIds: Set<String> = []

    private let goalViewModel = GoalViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private var pendingManualCreate = false
    private let suggestionsTask = TaskGuard()

    init() {
        goalViewModel.$allGoals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goals in
                self?.activeGoals = goals.filter { $0.status.isOpen }
                self?.completedGoals = goals.filter { $0.status == .completed }
            }
            .store(in: &cancellables)

        goalViewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        goalViewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorMessage = message
                if message != nil, self?.pendingManualCreate == true {
                    self?.isCreating = false
                    self?.pendingManualCreate = false
                }
            }
            .store(in: &cancellables)

        goalViewModel.$successMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self else { return }
                self.successMessage = message
                if message != nil, self.pendingManualCreate {
                    self.manualTitle = ""
                    self.manualTimeframe = ""
                    self.isCreating = false
                    self.pendingManualCreate = false
                }
            }
            .store(in: &cancellables)
    }

    var highlightedActiveTitles: [String] {
        activeGoals.prefix(2).map(\.title)
    }

    var latestCompletedTitle: String? {
        completedGoals.first?.title
    }

    var completedThisWeek: Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let iso = ISO8601DateFormatter()
        return completedGoals.filter { goal in
            guard let str = goal.completedAt, let date = iso.date(from: str) else { return false }
            return date >= weekStart
        }.count
    }

    func load() {
        goalViewModel.loadGoals()
        loadSuggestions()
    }

    func cancelAll() {
        goalViewModel.cancelAll()
        suggestionsTask.cancel()
    }

    func refresh() async {
        await goalViewModel.refresh()
        loadSuggestions()
    }

    func createManualGoal() {
        pendingManualCreate = true
        isCreating = true
        goalViewModel.createGoal(title: manualTitle, timeframe: manualTimeframe)
        if !goalViewModel.isCreateInFlight() && errorMessage != nil {
            isCreating = false
            pendingManualCreate = false
        }
    }

    func completeGoal(_ goal: APIGoal) {
        goalViewModel.completeGoal(goal)
    }

    func deleteGoal(_ goal: APIGoal) {
        goalViewModel.deleteGoal(goal)
    }

    func isInFlight(goalId: String) -> Bool {
        goalViewModel.isInFlight(goalId: goalId)
    }

    // MARK: — AI Suggestions

    func loadSuggestions() {
        suggestionsTask.run { [weak self] in
            await self?.performLoadSuggestions()
        }
    }

    func acceptSuggestion(_ suggestion: APIGoalSuggestion) {
        guard inFlightSuggestionIds.insert(suggestion.id).inserted else { return }
        Task {
            defer { inFlightSuggestionIds.remove(suggestion.id) }
            do {
                let _: APIGoal = try await APIClient.shared.requestWithAutoRefresh(
                    .acceptGoalSuggestion(id: suggestion.id)
                )
                aiSuggestions.removeAll { $0.id == suggestion.id }
                goalViewModel.loadGoals()
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func rejectSuggestion(_ suggestion: APIGoalSuggestion) {
        guard inFlightSuggestionIds.insert(suggestion.id).inserted else { return }
        Task {
            defer { inFlightSuggestionIds.remove(suggestion.id) }
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .rejectGoalSuggestion(id: suggestion.id)
                )
                aiSuggestions.removeAll { $0.id == suggestion.id }
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func isSuggestionInFlight(id: String) -> Bool {
        inFlightSuggestionIds.contains(id)
    }

    private func performLoadSuggestions() async {
        do {
            let result: [APIGoalSuggestion] = try await APIClient.shared.requestWithAutoRefresh(
                .getGoalSuggestions(sourceType: nil, journalEntryId: nil, sessionId: nil)
            )
            guard !Task.isCancelled else { return }
            aiSuggestions = result.filter { $0.suggestionType == .createGoal }
        } catch is CancellationError {
            return
        } catch {
            // Sessizce geç — AI önerileri kritik değil; ana akış bozulmasın
        }
    }
}
