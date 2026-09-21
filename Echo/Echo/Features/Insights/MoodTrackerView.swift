import SwiftUI

@Observable
@MainActor
private final class MoodTrackerViewModel {
    private(set) var eligibility: InsightEligibility?
    private(set) var summary: PeriodSummary?
    private(set) var isLoading = false
    private(set) var error: AppError?
    var selectedPeriod: Int
    @ObservationIgnored private let service: any InsightsServicing
    @ObservationIgnored private var loadID = UUID()

    init(periodDays: Int, service: any InsightsServicing) {
        selectedPeriod = periodDays
        self.service = service
    }

    func load() async {
        let requestedPeriod = selectedPeriod
        let currentLoadID = UUID()
        loadID = currentLoadID
        isLoading = true
        error = nil
        defer { if loadID == currentLoadID { isLoading = false } }
        do {
            if eligibility == nil { eligibility = try await service.eligibility() }
            try Task.checkCancellation()
            guard loadID == currentLoadID, selectedPeriod == requestedPeriod else { return }
            guard eligibility?.periods.first(where: { $0.days == requestedPeriod })?.isUnlocked == true else {
                summary = nil
                return
            }
            let summary = try await service.summary(periodDays: requestedPeriod, endDay: nil)
            try Task.checkCancellation()
            guard loadID == currentLoadID, selectedPeriod == requestedPeriod else { return }
            self.summary = summary
        } catch is CancellationError {
            return
        } catch {
            guard loadID == currentLoadID else { return }
            self.error = AppError.from(error)
        }
    }
}

struct MoodTrackerView: View {
    @Environment(\.locale) private var locale
    @State private var model: MoodTrackerViewModel
    private let timeZone: TimeZone

    init(periodDays: Int, service: any InsightsServicing, timeZone: TimeZone) {
        self.timeZone = timeZone
        _model = State(initialValue: MoodTrackerViewModel(periodDays: periodDays, service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                if let periods = model.eligibility?.periods, !periods.isEmpty {
                    EchoSegmentedControl(selection: $model.selectedPeriod,
                                         options: periods.map { .init($0.days, $0.label) })
                }
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.load() } }
                    })
                }
                if let selected = model.eligibility?.periods.first(where: { $0.days == model.selectedPeriod }),
                   !selected.isUnlocked {
                    EchoEmptyState("insights.locked", message: "insights.lockedMessage", systemImage: "lock")
                } else if let summary = model.summary {
                    EchoMoodChart(points: points(summary.dailyMoodScores))
                    bestAndWorst(summary)
                    dailyList(summary)
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 260)
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("mood.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .task(id: model.selectedPeriod) {
            guard model.eligibility != nil else { return }
            await model.load()
        }
    }

    private func bestAndWorst(_ summary: PeriodSummary) -> some View {
        HStack(alignment: .top, spacing: AppTheme.space.xs) {
            dayCard(title: "mood.bestDay", day: summary.bestDay, systemImage: "arrow.up.right")
            dayCard(title: "mood.hardestDay", day: summary.worstDay, systemImage: "arrow.down.right")
        }
    }

    private func dayCard(title: LocalizedStringKey, day: LocalDay?, systemImage: String) -> some View {
        EchoCard(style: .flat) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                Image(systemName: systemImage).foregroundStyle(AppTheme.color.content.accent)
                Text(title).echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.tertiary)
                if let day {
                    Text(JournalPresentation.dayTitle(day, locale: locale, timeZone: timeZone))
                        .echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.primary)
                } else {
                    Text("common.notAvailable").echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
        }
    }

    private func dailyList(_ summary: PeriodSummary) -> some View {
        let days = summary.dailyMoodScores.filter { $0.entryCount > 0 }.reversed()
        return VStack(alignment: .leading, spacing: 0) {
            EchoSectionHeader("mood.daily")
                .padding(.bottom, AppTheme.space.xs)
            EchoCard(style: .flat, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, score in
                        HStack(spacing: AppTheme.space.xs) {
                            EchoMoodGlyph(level: EchoMoodLevel(moodScore: score.moodScore ?? 0.5), size: 18)
                            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                                Text(score.day.map { JournalPresentation.dayTitle($0, locale: locale, timeZone: timeZone) } ?? "")
                                    .echoTextStyle(.body).foregroundStyle(AppTheme.color.content.primary)
                                Text(score.moodLabel ?? "").echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                            }
                            Spacer()
                            Text(String(format: String(localized: "mood.entryCount"), score.entryCount))
                                .echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                        }
                        .padding(AppTheme.space.sm)
                        if index < days.count - 1 { EchoDivider(insetLeading: 52) }
                    }
                }
            }
        }
    }

    private func points(_ scores: [PeriodSummary.DailyScore]) -> [EchoMoodPoint] {
        scores.compactMap { score in
            guard let day = score.day, let date = day.startDate(in: timeZone) else { return nil }
            return EchoMoodPoint(id: day.isoString, date: date, score: score.moodScore, caption: score.moodLabel,
                                 entryCount: score.entryCount)
        }
    }
}
