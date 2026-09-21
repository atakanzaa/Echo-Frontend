import SwiftUI

struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(\.locale) private var locale
    @State private var model: TodayViewModel

    private let user: AuthenticatedUser
    private let timeZone: TimeZone

    init(user: AuthenticatedUser,
         journal: any JournalServicing,
         insights: any InsightsServicing,
         notifications: any NotificationServicing,
         goals: any GoalServicing) {
        self.user = user
        timeZone = user.resolvedTimeZone
        _model = State(initialValue: TodayViewModel(journal: journal, insights: insights,
                                                    notifications: notifications, goalService: goals,
                                                    timeZone: user.resolvedTimeZone))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                statusBanners
                    .padding(.top, AppTheme.space.md)
                EchoQuestionHero(question: question,
                                 actionTitle: "today.speakAction",
                                 secondaryTitle: "today.writeAction",
                                 onRecord: { router.present(.recording) },
                                 onWrite: { router.present(.composer) })
                    .padding(.top, AppTheme.space.xxl)
                    .padding(.bottom, AppTheme.space.xxxl)
                todaySection
                suggestionSection
                goalsSection
                memorySection
                EchoHairline()
                    .padding(.top, AppTheme.layout.sectionGap)
                EchoLinkRow(title: "today.coach", subtitle: "today.coachMessage") {
                    router.present(.coachChat(sessionId: nil))
                }
            }
            .frame(maxWidth: AppTheme.layout.readableEntryWidth, alignment: .leading)
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xxl)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.color.bg.canvas)
        .environment(\.timeZone, timeZone)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.notifications) } label: {
                    Image(systemName: model.unreadNotificationCount > 0 ? "bell.badge" : "bell")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .accessibilityLabel(Text("notifications.title"))
                }
            }
        }
        .refreshable { await model.load() }
        .task { await model.load() }
    }

    /// Sayfa başlığı: tarih, selam ve sunucunun streak bilgisi. Ayrı bir "Bugün" başlığı tekrarlanmaz.
    private var masthead: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            if let today = model.today {

                Text(JournalPresentation.dayTitle(today, locale: locale, timeZone: timeZone))
                    .echoTextStyle(.caption2)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.color.content.tertiary)
            }
            Text(greeting)
                .echoTextStyle(.display)
                .foregroundStyle(AppTheme.color.content.primary)
            if user.currentStreak > 0 {

                HStack(spacing: AppTheme.space.xxs) {
                    Circle()
                        .fill(user.recordedToday ? AppTheme.color.accent.secondary : AppTheme.color.border.strong)
                        .frame(width: 6, height: 6)
                    Text(streakLine)
                        .echoTextStyle(.subhead)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
                .padding(.top, AppTheme.space.xxxs)
            }
        }
        .padding(.top, AppTheme.space.xs)
    }

    @ViewBuilder private var statusBanners: some View {
        if let error = model.error {

            EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.load() } }
            })
        }
        let pendingCount = environment.pendingJournals.items.filter { $0.ownerUserID == user.id }.count
        if pendingCount > 0 {

            EchoBanner(kind: .info,
                       title: String(format: String(localized: "today.pendingTitle"), pendingCount),
                       message: String(localized: "today.pendingMessage"))
        }
    }

    /// Bugünün kayıtları zaman çizelgesi olarak; boşsa tek satır sessiz metin.
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EchoSectionLabel(title: "today.section.today")
            if model.entries.isEmpty {

                if model.isLoading {

                    ProgressView().padding(.vertical, AppTheme.space.sm)
                } else {
                    Text("today.emptyDay")
                        .echoTextStyle(.callout)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                        .padding(.vertical, AppTheme.space.xs)
                }
            } else {
                ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in

                    if index > 0 { EchoHairline(leadingInset: 44 + AppTheme.space.sm) }
                    timelineRow(entry)
                }
            }
        }
    }

    private func timelineRow(_ entry: JournalEntry) -> some View {
        EchoTimelineRow(time: entry.recordedAt,
                        text: entry.analysis?.summary ?? entry.transcript ?? "",
                        moodLevel: entry.analysis?.moodCategory.displayLevel,
                        caption: entry.analysis?.moodLabel,
                        statusText: JournalPresentation.statusText(for: entry)) {
            router.push(.journalEntry(id: entry.id))
        }
    }

    /// Sunucunun hedef önerisi; buton metinleri sunucudan gelir.
    @ViewBuilder private var suggestionSection: some View {
        if let suggestion = model.goalSuggestions.first {

            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                EchoSectionLabel(title: "today.section.suggestion")
                Text(suggestion.message)
                    .echoTextStyle(.body)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: AppTheme.space.md) {
                    Button { Task { await model.accept(suggestion) } } label: {
                        Text(suggestion.primaryActionLabel)
                            .echoTextStyle(.headline)
                            .foregroundStyle(AppTheme.color.content.accent)
                    }
                    Button { Task { await model.reject(suggestion) } } label: {
                        Text(suggestion.secondaryActionLabel)
                            .echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    @ViewBuilder private var goalsSection: some View {
        if !model.goals.isEmpty {

            VStack(alignment: .leading, spacing: 0) {
                EchoSectionLabel(title: "today.section.goals", actionTitle: "common.all") { router.push(.goals) }
                ForEach(Array(model.goals.prefix(3).enumerated()), id: \.element.id) { index, goal in

                    if index > 0 { EchoHairline(leadingInset: 33) }
                    EchoChecklistRow(title: goal.title, detail: goal.timeframe) {
                        Task { await model.complete(goal) }
                    }
                }
            }
            .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    @ViewBuilder private var memorySection: some View {
        if let memory = model.memories.first {

            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                EchoSectionLabel(title: "today.section.memory")
                EchoQuoteBlock(text: memory.summary,
                               caption: String(format: String(localized: "today.yearsAgo"), memory.yearsAgo)
                                   + " · " + memory.moodLabel) {
                    router.push(.journalEntry(id: memory.id))
                }
            }
            .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    /// Sunucunun son yansımasındaki soru; yoksa uygulamanın genel davet cümlesi.
    private var question: String {
        let reflective = model.recentEntries
            .compactMap { $0.analysis?.reflectiveQuestion }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return reflective ?? String(localized: "record.prompt")
    }

    private var streakLine: String {
        let base = String(format: String(localized: "today.streakLine"), user.currentStreak)
        return user.recordedToday ? base + " · " + String(localized: "today.recordedToday") : base
    }

    private var greeting: String {
        let name = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { return String(localized: "today.greetingGeneric") }
        return String(format: String(localized: "today.greeting"), name)
    }
}
