import SwiftUI

/// Bugün ekranı (docs/design/today/HANDOFF.md §2, §11). Kullanıcının geçmiş verisiyle dolu, tek dolgu yüzeyli sayfa.
/// Tüm değerler sunucudan gelir; ekran yalnız seçer ve biçimlendirir.
struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(\.locale) private var locale
    @State private var model: TodayViewModel

    private let initialUser: AuthenticatedUser
    private let timeZone: TimeZone

    init(user: AuthenticatedUser, environment: AppEnvironment) {
        initialUser = user
        timeZone = user.resolvedTimeZone
        _model = State(initialValue: TodayViewModel(journal: environment.journal, insights: environment.insights,
                                                    notifications: environment.notifications, goalService: environment.goals,
                                                    capsuleService: environment.capsules, coach: environment.coach,
                                                    timeZone: user.resolvedTimeZone))
    }

    private var user: AuthenticatedUser { environment.session.state.user ?? initialUser }
    private var isNewUser: Bool { user.totalEntries == 0 && model.entries.isEmpty }
    private var showsTimelineFirst: Bool { user.recordedToday && !model.entries.isEmpty }
    private var isOffline: Bool { !environment.network.isOnline || (model.error != nil && model.hasLoadedOnce) }

    var body: some View {
        ScrollView {
            // Bölüm sayısı az; tembel yığın yükseklik tahminiyle scroll'u zıplatıyordu.
            VStack(alignment: .leading, spacing: 0) {
                if isOffline {

                    OfflineStrip(sinceText: model.lastLoadedAt.map { $0.formatted(date: .omitted, time: .shortened) }) {
                        Task { await reload() }
                    }
                    .padding(.bottom, AppTheme.space.md)
                }
                header
                if showsTimelineFirst {

                    timeline.padding(.top, AppTheme.layout.sectionGap)
                }
                hero.padding(.top, AppTheme.layout.sectionGap)
                capsuleRow
                weeklyPanel
                if isNewUser { afterFirstEntry.padding(.top, AppTheme.layout.sectionGap) }
                memory
                goalsSection.padding(.top, AppTheme.layout.sectionGap)
                progress
                knowsYouCoach.padding(.top, AppTheme.layout.sectionGap)
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.top, AppTheme.space.xs)
            .padding(.bottom, AppTheme.space.xxl)
        }
        .background(AppTheme.color.bg.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.timeZone, timeZone)
        .refreshable { await reload() }
        .task { await reload() }
        .onDisappear { model.stop() }
    }

    private func reload() async {
        async let session: Void = environment.session.refreshUser()
        async let data: Void = model.load()
        async let usage: Void = environment.usage.refresh()
        _ = await (session, data, usage)
    }

    // MARK: b · Günün girişi

    private var header: some View {
        TodayHeader(dateText: dateText(model.today),
                    greeting: greeting,
                    streakDays: user.currentStreak,
                    recordedToday: user.recordedToday,
                    todayEntryCount: model.todayEntryCount,
                    unreadCount: model.unreadNotificationCount,
                    onNotifications: { router.push(.notifications) },
                    onStreak: { router.push(.achievements) })
    }

    /// Selam metni kullanıcının saat dilimindeki saate göre seçilir; yalnız metin seçimidir.
    private var greeting: String {
        let prefix: String
        if user.totalEntries == 0 {

            prefix = String(localized: "today.greeting.welcome")
        } else {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            switch calendar.component(.hour, from: Date()) {
            case 5..<12: prefix = String(localized: "today.greeting.morning")
            case 12..<18: prefix = String(localized: "today.greeting.day")
            default: prefix = String(localized: "today.greeting.evening")
            }
        }
        guard let name = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return prefix }
        return prefix + ", " + name
    }

    // MARK: c · Bugünün kayıtları

    private var timeline: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            EchoSectionTitle(title: String(localized: "today.timeline.title"),
                             actionTitle: "today.timeline.toJournal") { router.selectedTab = .journal }
            // Gün kronolojik okunur: sabah üstte. Yalnız gösterim sırası; değer üretilmez.
            let dayEntries = model.entries.sorted { $0.recordedAt < $1.recordedAt }
            ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, entry in

                EchoTimelineRow(time: entry.recordedAt,
                                state: timelineState(entry),
                                connectsAbove: index > 0,
                                connectsBelow: index < dayEntries.count - 1) {
                    router.push(.journalEntry(id: entry.id))
                }
            }
        }
    }

    private func timelineState(_ entry: JournalEntry) -> EchoTimelineRow.State {
        switch entry.status {
        case .succeeded:
            guard let analysis = entry.analysis else { return .failed(transcript: entry.transcript, canRetry: false) }
            return .completed(moodLevel: EchoMoodLevel(moodScore: analysis.moodScore),
                              moodLabel: analysis.moodLabel,
                              energyLabel: environment.remoteConfig.vocabulary.label(energy: analysis.energyLevel),
                              summary: analysis.summary,
                              topics: analysis.topics)
        case .failed, .cancelled:
            // Sunucuda başarısız analizi yeniden başlatan uç yok; yeniden deneme yalnız cihazdaki gönderimler içindir.
            return .failed(transcript: entry.transcript, canRetry: false)
        case .retryScheduled where entry.errorCode == "AI_QUOTA_EXHAUSTED":
            // Kayıt saklandı; analiz kullanım hakkı yenilenince sunucuda kendiliğinden yapılır.
            return .waitingForAllowance(transcript: entry.transcript, resumesAt: environment.usage.usage?.resetsAt)
        case .queued, .processing, .retryScheduled, .unknown:
            return .processing(transcript: entry.transcript)
        }
    }

    // MARK: d · Günün sorusu

    @ViewBuilder private var hero: some View {
        if let source = model.questionSource, let analysis = source.analysis {

            EchoQuestionHero(label: questionLabel(for: source),
                             question: analysis.reflectiveQuestion,
                             moodLevel: EchoMoodLevel(moodScore: analysis.moodScore),
                             actionTitle: "today.question.action",
                             writeTitle: "today.question.write",
                             onRecord: { router.present(.recording(prompt: analysis.reflectiveQuestion, sourceEntryID: source.id)) },
                             onWrite: { router.present(.composer) })
        } else {
            EchoQuestionHero(label: String(localized: "today.welcome.label"),
                             question: String(localized: "today.welcome.question"),
                             message: String(localized: "today.welcome.body"),
                             moodLevel: nil,
                             actionTitle: "today.question.action",
                             writeTitle: "today.question.write",
                             onRecord: { router.present(.recording()) },
                             onWrite: { router.present(.composer) })
        }
    }

    /// Sorunun geldiği kaydın günü sunucunun `today` değeriyle karşılaştırılır; cihaz saati kullanılmaz.
    private func questionLabel(for entry: JournalEntry) -> String {
        guard let today = model.today, let day = entry.entryDay else { return String(localized: "today.question.fromLast") }
        if day == today { return String(localized: "today.question.fromToday") }
        if let todayDate = today.startDate(in: timeZone),
           let yesterday = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: todayDate),
           LocalDay(date: yesterday, timeZone: timeZone) == day {

            return String(localized: "today.question.fromYesterday")
        }
        return String(localized: "today.question.fromLast")
    }

    // MARK: e · Kapsül

    @ViewBuilder private var capsuleRow: some View {
        if let capsules = model.capsules, capsules.openableCount > 0 || capsules.nextUnlockAt != nil {

            CapsuleRow(openableCount: capsules.openableCount,
                       nextUnlockText: capsules.nextUnlockAt.map { $0.formatted(.dateTime.day().month(.wide)) }) {
                if capsules.openableCount > 0, let id = capsules.nextCapsuleID {

                    router.push(.capsule(id: id))
                } else {
                    router.push(.capsules)
                }
            }
            .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    // MARK: f · Son 7 gün

    @ViewBuilder private var weeklyPanel: some View {
        if let weekly = model.weekly {

            let days = weekly.weeklyTrend.enumerated().map { index, point in

                WeekMoodStrip.Day(id: point.day?.isoString ?? "\(index)",
                                  shortLabel: dayLabel(point.day, format: "EEE"),
                                  accessibilityName: dayLabel(point.day, format: "EEEE"),
                                  moodScore: point.moodScore,
                                  entryCount: point.entryCount,
                                  isToday: point.day != nil && point.day == model.today)
            }
            WeeklyPanel(title: isNewUser ? String(localized: "today.week.emptyTitle") : weekly.periodLabel,
                        days: days,
                        average: weekly.weeklyAverage,
                        trend: weekly.moodTrend,
                        trendLabel: weekly.moodTrend.map { environment.remoteConfig.vocabulary.label(trend: $0) },
                        narrative: weekly.hasSufficientData ? model.weekSummary?.narrativeSummary : nil,
                        themes: weekly.hasSufficientData
                            ? weekly.themes.map { WeeklyPanel.Theme(tag: $0.tag, count: $0.count, isTrending: $0.isTrending) }
                            : [],
                        isEmpty: isNewUser,
                        onDayTap: { router.push(.moodTracker(periodDays: 7)) },
                        onMore: { router.push(.insights) })
                .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    // MARK: g · İlk kaydından sonra

    private var afterFirstEntry: some View {
        VStack(alignment: .leading, spacing: 0) {
            EchoSectionTitle(title: String(localized: "today.after.title"))
                .padding(.bottom, AppTheme.space.xs)
            afterStep(1, "today.after.summary.title", "today.after.summary.body")
            EchoHairline(leadingInset: 40)
            afterStep(2, "today.after.mood.title", "today.after.mood.body")
            EchoHairline(leadingInset: 40)
            afterStep(3, "today.after.question.title", "today.after.question.body")
        }
    }

    private func afterStep(_ number: Int, _ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: AppTheme.space.sm) {
            Text(verbatim: "\(number)")
                .echoTextStyle(.caption).fontWeight(.semibold)
                .foregroundStyle(AppTheme.color.content.secondary)
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(AppTheme.color.border.default, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
                Text(body).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppTheme.space.xs)
        .accessibilityElement(children: .combine)
    }

    // MARK: h · Geçmişte bugün

    @ViewBuilder private var memory: some View {
        if let memory = model.memories.first {

            PastTodayBlock(caption: String(format: String(localized: "today.memory.yearsAgo"), memory.yearsAgo)
                               + (memory.day.map { " · " + dateText($0) } ?? ""),
                           moodLevel: EchoMoodLevel(moodScore: memory.moodScore),
                           moodLabel: memory.moodLabel,
                           quote: memory.summary) {
                router.push(.journalEntry(id: memory.id))
            }
            .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    // MARK: i · Hedefler

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            EchoSectionTitle(title: String(localized: isNewUser ? "today.goals.section" : "today.goals.title"),
                             subtitle: completedThisWeekText,
                             actionTitle: model.goals.isEmpty ? nil : "common.all",
                             action: { router.push(.goals) })
            if model.goals.isEmpty {

                Button { router.push(.createGoal) } label: {
                    HStack(spacing: AppTheme.space.sm) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().strokeBorder(AppTheme.color.border.default, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                        Text("today.goals.empty").echoTextStyle(.body).foregroundStyle(AppTheme.color.content.primary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.color.content.tertiary)
                    }
                    .frame(minHeight: AppTheme.layout.listRowMinHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                EchoHairline()
            } else {
                ForEach(Array(model.goals.prefix(5).enumerated()), id: \.element.id) { index, goal in

                    if index > 0 { EchoHairline(leadingInset: 35) }
                    EchoChecklistRow(title: goal.title,
                                     detail: goal.timeframe,
                                     isCompleted: goal.status == .completed,
                                     onComplete: { Task { await model.complete(goal) } },
                                     onOpen: { router.push(.goals) })
                }
            }
            if let suggestion = model.goalSuggestions.first {

                GoalSuggestionRow(message: suggestion.message,
                                  primaryTitle: suggestion.primaryActionLabel,
                                  secondaryTitle: suggestion.secondaryActionLabel,
                                  onAccept: { Task { await model.accept(suggestion) } },
                                  onReject: { Task { await model.reject(suggestion) } })
                    .padding(.top, AppTheme.space.xs)
            }
        }
    }

    private var completedThisWeekText: String? {
        guard let count = model.goalStats?.completedThisWeek, count > 0 else { return nil }
        return String(format: String(localized: "today.goals.completedThisWeek"), count)
    }

    // MARK: j · İlerleme

    @ViewBuilder private var progress: some View {
        if let achievements = model.achievements {

            let badge = achievements.nextBadge
            ProgressSection(streakMessage: achievements.streakMessage,
                            badgeEmoji: badge?.emoji,
                            badgeTitle: badge?.title,
                            badgeProgress: badge?.progress,
                            badgeRemainingText: badge.flatMap { badge in
                                badge.progress > 0
                                    ? String(format: String(localized: "today.progress.remaining"), badge.remaining)
                                    : badge.criteriaDescription
                            },
                            earnedText: "\(achievements.earnedCount)/\(achievements.totalCount)",
                            statsText: isNewUser
                                ? String(localized: "today.progress.newUserHint")
                                : String(format: String(localized: "today.progress.stats"), user.longestStreak, user.totalEntries),
                            onBadge: { if let badge { router.push(.achievementDetail(badgeKey: badge.key)) } })
                .padding(.top, AppTheme.layout.sectionGap)
        }
    }

    // MARK: k · Echo seni tanıyor + koç

    private var knowsYouCoach: some View {
        KnowsYouCoachBlock(knowsYou: model.profile?.emotionalPatterns,
                           coachTitle: model.lastCoachSession == nil ? "today.coach.meet" : "today.coach.title",
                           coachSubtitle: model.lastCoachSession.map { String(format: String(localized: "today.coach.last"), $0.title) }
                               ?? String(localized: "today.coach.meetBody"),
                           onCoach: { router.present(.coachChat(sessionId: model.lastCoachSession?.id)) })
    }

    // MARK: Biçimlendirme

    private func dateText(_ day: LocalDay?) -> String {
        guard let day, let date = day.startDate(in: timeZone) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: date)
    }

    private func dayLabel(_ day: LocalDay?, format: String) -> String {
        guard let day, let date = day.startDate(in: timeZone) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
