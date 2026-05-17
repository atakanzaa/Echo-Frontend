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

    private let goalViewModel = GoalViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private var pendingManualCreate = false

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

    func load() {
        goalViewModel.loadGoals()
    }

    func cancelAll() {
        goalViewModel.cancelAll()
    }

    func refresh() async {
        await goalViewModel.refresh()
    }

    func createManualGoal() {
        pendingManualCreate = true
        isCreating = true
        goalViewModel.createGoal(title: manualTitle, timeframe: manualTimeframe)
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
}
