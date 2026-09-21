import Foundation
import Observation

/// Bugün ekranının verisi (docs/design/today/HANDOFF.md §4). Her kaynak ayrı yüklenir ve ayrı başarısız olabilir;
/// başarısız olan bölüm gizlenir, önceki veri silinmez. Değerler sunucudan gelir; burada yalnız seçim yapılır.
@Observable
@MainActor
final class TodayViewModel {
    private(set) var today: LocalDay?
    /// Bugünün kayıt sayısı takvimden gelir; liste sayılmaz.
    private(set) var todayEntryCount: Int?
    private(set) var entries: [JournalEntry] = []
    private(set) var recentEntries: [JournalEntry] = []
    private(set) var memories: [OnThisDayEntry] = []
    private(set) var goals: [Goal] = []
    private(set) var goalStats: GoalStats?
    private(set) var goalSuggestions: [GoalSuggestion] = []
    private(set) var weekly: AIInsights?
    private(set) var weekSummary: PeriodSummary?
    private(set) var profile: ProfileSummary?
    private(set) var achievements: Achievements?
    private(set) var capsules: CapsuleSummary?
    private(set) var lastCoachSession: CoachSession?
    private(set) var unreadNotificationCount = 0
    private(set) var isLoading = false
    private(set) var hasLoadedOnce = false
    private(set) var lastLoadedAt: Date?
    private(set) var error: AppError?

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private let insights: any InsightsServicing
    @ObservationIgnored private let notifications: any NotificationServicing
    @ObservationIgnored private let goalService: any GoalServicing
    @ObservationIgnored private let capsuleService: any CapsuleServicing
    @ObservationIgnored private let coach: any CoachServicing
    @ObservationIgnored private let timeZone: TimeZone
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init(journal: any JournalServicing, insights: any InsightsServicing, notifications: any NotificationServicing,
         goalService: any GoalServicing, capsuleService: any CapsuleServicing, coach: any CoachServicing,
         timeZone: TimeZone) {
        self.journal = journal
        self.insights = insights
        self.notifications = notifications
        self.goalService = goalService
        self.capsuleService = capsuleService
        self.coach = coach
        self.timeZone = timeZone
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer {
            isLoading = false
            hasLoadedOnce = true
        }
        do {
            // Takvim kullanıcının "bugün"ünü verir; ay değişimi sunucunun gününe göre izlenir.
            let bootstrap = LocalDay(date: Date(), timeZone: timeZone)
            var month = try await insights.calendar(year: bootstrap.year, month: bootstrap.month)
            if let serverToday = month.today, serverToday.year != month.year || serverToday.month != month.month {

                month = try await insights.calendar(year: serverToday.year, month: serverToday.month)
            }
            today = month.today
            todayEntryCount = month.today.flatMap { day in month.days.first { $0.day == day.day }?.entryCount }
            if let today {

                entries = try await journal.entries(day: today, cursor: nil, size: 20).items
            }
            lastLoadedAt = Date()
        } catch {
            self.error = AppError.from(error)
        }

        async let loadedRecent = journal.recent(cursor: nil, size: 5)
        async let loadedMemories = journal.onThisDay()
        async let loadedUnread = notifications.unreadCount()
        async let loadedGoals = goalService.todayGoals()
        async let loadedGoalStats = goalService.stats()
        async let loadedSuggestions = goalService.suggestions(sourceType: nil, suggestionType: nil,
                                                               journalEntryID: nil, coachSessionID: nil)
        async let loadedWeekly = insights.insights(periodDays: 7)
        async let loadedSummary = insights.summary(periodDays: 7, endDay: today)
        async let loadedProfile = insights.profileSummary()
        async let loadedAchievements = insights.achievements()
        async let loadedCapsules = capsuleService.summary()
        async let loadedCoach = coach.sessions(cursor: nil, size: 1)

        if let page = try? await loadedRecent { recentEntries = page.items }
        if let value = try? await loadedMemories { memories = value }
        if let value = try? await loadedUnread { unreadNotificationCount = value }
        if let value = try? await loadedGoals { goals = value }
        if let value = try? await loadedGoalStats { goalStats = value }
        if let value = try? await loadedSuggestions { goalSuggestions = value }
        if let value = try? await loadedWeekly { weekly = value }
        if let value = try? await loadedSummary { weekSummary = value }
        if let value = try? await loadedProfile { profile = value }
        if let value = try? await loadedAchievements { achievements = value }
        if let value = try? await loadedCapsules { capsules = value }
        if let page = try? await loadedCoach { lastCoachSession = page.items.first }

        trackProcessingEntries()
    }

    /// Tamamlanan hedef listeden düşmez; sunucunun döndürdüğü hâliyle yerinde güncellenir.
    func complete(_ goal: Goal) async {
        do {
            let updated = try await goalService.complete(id: goal.id)
            if let index = goals.firstIndex(where: { $0.id == goal.id }) { goals[index] = updated }
            goalStats = try? await goalService.stats()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func accept(_ suggestion: GoalSuggestion) async {
        do {
            let goal = try await goalService.acceptSuggestion(id: suggestion.id)
            goalSuggestions.removeAll { $0.id == suggestion.id }
            if goal.status.isOpen { goals.insert(goal, at: 0) }
            goalStats = try? await goalService.stats()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func reject(_ suggestion: GoalSuggestion) async {
        do {
            try await goalService.rejectSuggestion(id: suggestion.id)
            goalSuggestions.removeAll { $0.id == suggestion.id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// İşlenen kayıt varken sunucunun `poll_after_ms` aralığıyla tek döngü; terminal durumda satır yerinde güncellenir.
    private func trackProcessingEntries() {
        pollTask?.cancel()
        let pending = entries.filter { !$0.status.isTerminalForDisplay }
        guard !pending.isEmpty else { return }
        pollTask = Task { [weak self] in
            guard let self else { return }
            for entry in pending {

                while !Task.isCancelled {

                    guard let progress = try? await self.progress(of: entry) else {
                        try? await Task.sleep(for: .seconds(3))
                        continue
                    }
                    if progress.isTerminal {

                        if let refreshed = try? await journal.entry(id: entry.id),
                           let index = entries.firstIndex(where: { $0.id == entry.id }) {

                            entries[index] = refreshed
                        }
                        break
                    }
                    try? await Task.sleep(for: progress.pollInterval)
                }
            }
        }
    }

    /// İş kimliği varsa operation ucu, eski kayıtlarda journal status ucu okunur (rules.md §5).
    private func progress(of entry: JournalEntry) async throws -> OperationProgress {
        if let operationID = entry.operationID { return try await journal.operation(id: operationID) }
        return try await journal.status(id: entry.id)
    }

    // MARK: - Seçimler (hesap değil)

    /// Günün sorusu: analizi tamamlanmış en yeni kaydın yansıma sorusu.
    var questionSource: JournalEntry? {
        (entries + recentEntries)
            .filter { $0.status.isSucceeded && !($0.analysis?.reflectiveQuestion.isEmpty ?? true) }
            .max { $0.recordedAt < $1.recordedAt }
    }

    var isNewUser: Bool { (achievements?.totalEntries ?? 0) == 0 && entries.isEmpty && recentEntries.isEmpty }
}

extension EchoOperationStatus {
    /// Gösterim için: sunucunun terminal dediği durumlar; bilinmeyen durum beklemede sayılır.
    var isTerminalForDisplay: Bool {
        switch self {
        case .succeeded, .failed, .cancelled: true
        case .queued, .processing, .retryScheduled, .unknown: false
        }
    }
}
