import SwiftUI
import UniformTypeIdentifiers

struct InsightsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.locale) private var locale
    @State private var model: InsightsViewModel
    @State private var snapshot: InsightsSnapshot?

    private let timeZone: TimeZone
    private let currentStreak: Int

    init(service: any InsightsServicing, timeZone: TimeZone, currentStreak: Int) {
        self.timeZone = timeZone
        self.currentStreak = currentStreak
        _model = State(initialValue: InsightsViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                periodPicker
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.loadSelectedPeriod() } }
                    })
                }
                content
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("insights.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { if model.eligibility == nil { await model.load() } }
        .task(id: model.selectedPeriod) {
            guard model.eligibility != nil else { return }
            await model.loadSelectedPeriod()
        }
        .task(id: model.summary?.narrativeSummary) { renderSnapshot() }
        .echoRefreshable { await model.load() }
    }

    @ViewBuilder private var periodPicker: some View {
        if let eligibility = model.eligibility, !eligibility.periods.isEmpty {
            EchoSegmentedControl(selection: $model.selectedPeriod,
                                 options: eligibility.periods.map { .init($0.days, $0.label) })
        }
    }

    @ViewBuilder private var content: some View {
        if let period = model.selectedEligibility, !period.isUnlocked {
            lockedPeriod(period)
        } else if let summary = model.summary, let report = model.report {
            reportContent(summary: summary, report: report)
        } else if model.isLoading {
            ProgressView().frame(maxWidth: .infinity, minHeight: 260)
        }
    }

    private func reportContent(summary: PeriodSummary, report: AIInsights) -> some View {
        Group {
            if report.hasSufficientData {
                EchoWeeklyReportCard(
                    title: report.periodLabel,
                    dateRangeText: dateRange(summary),
                    summary: summary.narrativeSummary,
                    points: points(summary.dailyMoodScores),
                    topics: summary.dominantTopics,
                    onOpen: { router.push(.moodTracker(periodDays: model.selectedPeriod)) }
                )

                if let snapshot {
                    ShareLink(item: snapshot, preview: SharePreview(report.periodLabel)) {
                        Label("insights.shareReport", systemImage: "square.and.arrow.up")
                            .echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.accent)
                    }
                }
            } else {
                EchoEmptyState("insights.insufficient", message: "insights.insufficientMessage", systemImage: "chart.xyaxis.line")
            }

            if summary.entryCount > 0 {
                section("insights.moodMap") {
                    EchoCard(style: .flat) { EchoMoodChart(points: points(summary.dailyMoodScores)) }
                }
            }

            if !report.suggestions.isEmpty {
                section("insights.patterns") {
                    ForEach(report.suggestions) { suggestion in
                        EchoInsightCard(title: suggestion.title, message: suggestion.body)
                    }
                }
            }

            statistics(summary: summary)

            if let profile = model.profile {
                profileSection(profile)
            } else if model.didLoadSupportingData {
                section("insights.profile") {
                    EchoEmptyState("insights.profileEmpty", systemImage: "person.text.rectangle")
                }
            }
        }
    }

    private func statistics(summary: PeriodSummary) -> some View {
        section("insights.statistics") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.space.xs) {
                    EchoStatTile(value: "\(summary.entryCount)", label: String(localized: "insights.entryCount"))
                        .frame(width: 132)
                    EchoStatTile(value: "\(summary.recordedDays)", label: String(localized: "insights.recordedDays"))
                        .frame(width: 132)
                    EchoStatTile(value: "\(currentStreak)", label: String(localized: "insights.currentStreak"))
                        .frame(width: 132)
                    if let stats = model.stats {
                        EchoStatTile(value: stats.totalWords.formatted(), label: String(localized: "insights.totalWords"))
                            .frame(width: 132)
                    }
                }
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
        }
    }

    private func profileSection(_ profile: ProfileSummary) -> some View {
        let paragraphs = [profile.userProfile, profile.emotionalPatterns, profile.valuesStrengths,
                          profile.growthTrajectory, profile.weeklyDigest].compactMap { $0 }.filter { !$0.isEmpty }
        return section("insights.profile") {
            if paragraphs.isEmpty {
                EchoEmptyState("insights.profileEmpty", systemImage: "person.text.rectangle")
            } else {
                EchoCard(style: .flat) {
                    VStack(alignment: .leading, spacing: AppTheme.space.sm) {
                        ForEach(paragraphs, id: \.self) { paragraph in
                            Text(paragraph).echoTextStyle(.body).foregroundStyle(AppTheme.color.content.secondary)
                        }
                    }
                }
            }
        }
    }

    private func lockedPeriod(_ period: InsightEligibility.Period) -> some View {
        EchoEmptyState("insights.locked", message: "insights.lockedMessage", systemImage: "lock") {
            VStack(spacing: AppTheme.space.xxs) {
                Text(String(format: String(localized: "insights.entryProgress"), period.currentEntries, period.requiredEntries))
                Text(String(format: String(localized: "insights.dayProgress"), period.currentDistinctDays, period.requiredDistinctDays))
            }
            .echoTextStyle(.footnote)
            .foregroundStyle(AppTheme.color.content.secondary)
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader(title)
            content()
        }
    }

    private func points(_ scores: [PeriodSummary.DailyScore]) -> [EchoMoodPoint] {
        scores.compactMap { score in
            guard let day = score.day, let date = day.startDate(in: timeZone) else { return nil }
            return EchoMoodPoint(id: day.isoString, date: date, score: score.moodScore, caption: score.moodLabel,
                                 entryCount: score.entryCount)
        }
    }

    private func dateRange(_ summary: PeriodSummary) -> String {
        guard let start = summary.startDay, let end = summary.endDay else { return "" }
        return "\(JournalPresentation.dayTitle(start, locale: locale, timeZone: timeZone)) – \(JournalPresentation.dayTitle(end, locale: locale, timeZone: timeZone))"
    }

    private func renderSnapshot() {
        guard let summary = model.summary, let report = model.report else {
            snapshot = nil
            return
        }
        let view = InsightShareCard(title: report.periodLabel, dateRange: dateRange(summary),
                                    summary: summary.narrativeSummary, topics: summary.dominantTopics)
            .frame(width: 640)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        snapshot = renderer.uiImage?.pngData().map(InsightsSnapshot.init(data:))
    }
}

private struct InsightShareCard: View {
    let title: String
    let dateRange: String
    let summary: String
    let topics: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.lg) {
            HStack {
                EchoRippleView(ringCount: 3, intensity: 0.5, isAnimating: false).frame(width: 52, height: 52)
                VStack(alignment: .leading) {
                    Text(title).echoTextStyle(.title1)
                    Text(dateRange).echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.secondary)
                }
            }
            Text(summary).echoTextStyle(.entry).foregroundStyle(AppTheme.color.content.primary)
            EchoWrapRow(items: topics) { EchoChip($0) }
            Text("common.appName").echoTextStyle(.caption2).textCase(.uppercase)
                .foregroundStyle(AppTheme.color.content.accent)
        }
        .padding(AppTheme.space.xxl)
        .background(AppTheme.color.bg.canvas)
    }
}

private struct InsightsSnapshot: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in snapshot.data }
            .suggestedFileName("Echo-Insights.png")
    }
}
