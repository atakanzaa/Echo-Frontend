import Foundation
import Observation

@Observable
@MainActor
final class TodayViewModel {
    private(set) var today: LocalDay?
    private(set) var entries: [JournalEntry] = []
    private(set) var recentEntries: [JournalEntry] = []
    private(set) var memories: [OnThisDayEntry] = []
    private(set) var goals: [Goal] = []
    private(set) var goalStats: GoalStats?
    private(set) var goalSuggestions: [GoalSuggestion] = []
    private(set) var unreadNotificationCount = 0
    private(set) var isLoading = false
    private(set) var error: AppError?

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private let insights: any InsightsServicing
    @ObservationIgnored private let notifications: any NotificationServicing
    @ObservationIgnored private let goalService: any GoalServicing
    @ObservationIgnored private let timeZone: TimeZone

    init(journal: any JournalServicing, insights: any InsightsServicing,
         notifications: any NotificationServicing, goalService: any GoalServicing,
         timeZone: TimeZone) {
        self.journal = journal
        self.insights = insights
        self.notifications = notifications
        self.goalService = goalService
        self.timeZone = timeZone
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let bootstrap = LocalDay(date: Date(), timeZone: timeZone)
            var month = try await insights.calendar(year: bootstrap.year, month: bootstrap.month)
            if let serverToday = month.today,
               serverToday.year != month.year || serverToday.month != month.month {
                month = try await insights.calendar(year: serverToday.year, month: serverToday.month)
            }
            today = month.today
            if let today {
                entries = try await journal.entries(day: today, cursor: nil, size: 20).items
            } else {
                entries = []
            }
            async let loadedMemories = journal.onThisDay()
            async let unreadCount = notifications.unreadCount()
            async let loadedRecent = journal.recent(cursor: nil, size: 5)
            async let loadedGoals = goalService.activeGoals(cursor: nil, size: 3)
            async let loadedGoalStats = goalService.stats()
            async let loadedSuggestions = goalService.suggestions(sourceType: nil, suggestionType: nil,
                                                                   journalEntryID: nil, coachSessionID: nil)
            memories = try await loadedMemories
            unreadNotificationCount = (try? await unreadCount) ?? unreadNotificationCount
            if let page = try? await loadedRecent { recentEntries = page.items }
            if let page = try? await loadedGoals { goals = page.items }
            goalStats = try? await loadedGoalStats
            goalSuggestions = (try? await loadedSuggestions) ?? goalSuggestions
        } catch {
            self.error = AppError.from(error)
        }
    }

    func complete(_ goal: Goal) async {
        do {
            _ = try await goalService.complete(id: goal.id)
            goals.removeAll { $0.id == goal.id }
            goalStats = try? await goalService.stats()
        } catch { self.error = AppError.from(error) }
    }

    func accept(_ suggestion: GoalSuggestion) async {
        do {
            let goal = try await goalService.acceptSuggestion(id: suggestion.id)
            goalSuggestions.removeAll { $0.id == suggestion.id }
            if goal.status.isOpen { goals.insert(goal, at: 0) }
            goalStats = try? await goalService.stats()
        } catch { self.error = AppError.from(error) }
    }

    func reject(_ suggestion: GoalSuggestion) async {
        do {
            try await goalService.rejectSuggestion(id: suggestion.id)
            goalSuggestions.removeAll { $0.id == suggestion.id }
        } catch { self.error = AppError.from(error) }
    }
}
