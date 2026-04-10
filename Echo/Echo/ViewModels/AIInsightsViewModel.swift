import Foundation
import Combine

@MainActor
final class AIInsightsViewModel: ObservableObject {

    @Published var insights:      APIAIInsightsResponse?
    @Published var selectedPeriod = 7
    @Published var isLoading      = false
    @Published var errorMessage:  String?
    @Published var periodOptions: [PeriodOption] = []
    private let insightsTask = TaskGuard()
    private let eligibilityTask = TaskGuard()

    struct PeriodOption: Identifiable {
        let id: Int
        let days: Int
        let label: String
        let unlocked: Bool
        let progress: String?
    }

    var moodPercentText: String {
        guard let i = insights else { return "—" }
        return String(format: "%.1f", i.moodScore * 10)
    }

    var trendText: String {
        guard let i = insights else { return "" }
        if !(i.hasPreviousPeriodData ?? false) { return "" }
        if abs(i.emotionalTrend) < 0.0001 { return "0.0" }
        let sign = i.emotionalTrend >= 0 ? "+" : ""
        return String(format: "%@%.1f", sign, i.emotionalTrend)
    }

    var hasSufficientData: Bool { insights?.hasSufficientData ?? false }
    var hasPreviousPeriodData: Bool { insights?.hasPreviousPeriodData ?? false }
    var isTrendFlat: Bool { abs(insights?.emotionalTrend ?? 0) < 0.0001 }
    var isTrendPositive: Bool { (insights?.emotionalTrend ?? 0) >= 0 }

    var selectedPeriodLabel: String {
        periodOptions.first(where: { $0.days == selectedPeriod })?.label ?? "ai.last_7_days"
    }

    func loadEligibility() {
        eligibilityTask.run { [weak self] in
            await self?.performLoadEligibility()
        }
    }

    func loadInsights() {
        insightsTask.run { [weak self] in
            await self?.performLoadInsights()
        }
    }

    func selectPeriod(_ days: Int) {
        if let option = periodOptions.first(where: { $0.days == days }), !option.unlocked {
            return
        }
        selectedPeriod = days
        loadInsights()
    }

    func refresh() async {
        await insightsTask.runAsync { [weak self] in
            await self?.performLoadInsights()
        }
    }

    func refreshAll() async {
        await eligibilityTask.runAsync { [weak self] in
            await self?.performLoadEligibility()
        }
    }

    func cancelAll() {
        insightsTask.cancel()
        eligibilityTask.cancel()
    }

    private func performLoadEligibility() async {
        do {
            let eligibility: APIInsightsPeriodEligibility = try await APIClient.shared.requestWithAutoRefresh(.getInsightsEligibility)
            let mapped = eligibility.periods.map { p in
                let label: String
                switch p.days {
                case 7: label = "ai.last_7_days"
                case 30: label = "ai.last_30_days"
                case 90: label = "ai.last_90_days"
                case 180: label = "ai.last_180_days"
                case 365: label = "ai.last_365_days"
                default: label = "\(p.days) days"
                }
                let progress = p.unlocked ? nil : "\(p.currentEntries)/\(p.requiredEntries)"
                return PeriodOption(
                    id: p.days,
                    days: p.days,
                    label: label,
                    unlocked: p.unlocked,
                    progress: progress
                )
            }
            periodOptions = mapped.sorted(by: { $0.days < $1.days })
            let selectedIsUnlocked = periodOptions.contains(where: { $0.days == selectedPeriod && $0.unlocked })
            if !selectedIsUnlocked {
                if let best = periodOptions.last(where: { $0.unlocked }) {
                    selectedPeriod = best.days
                } else {
                    selectedPeriod = 7
                }
            }
            await performLoadInsights()
        } catch is CancellationError {
            return
        } catch {
            periodOptions = [
                PeriodOption(id: 7, days: 7, label: "ai.last_7_days", unlocked: true, progress: nil),
                PeriodOption(id: 30, days: 30, label: "ai.last_30_days", unlocked: false, progress: nil),
                PeriodOption(id: 90, days: 90, label: "ai.last_90_days", unlocked: false, progress: nil),
                PeriodOption(id: 180, days: 180, label: "ai.last_180_days", unlocked: false, progress: nil),
                PeriodOption(id: 365, days: 365, label: "ai.last_365_days", unlocked: false, progress: nil),
            ]
            selectedPeriod = 7
            await performLoadInsights()
        }
    }

    private func performLoadInsights() async {
        isLoading = true
        errorMessage = nil
        do {
            let period = selectedPeriod
            let result: APIAIInsightsResponse = try await APIClient.shared.requestWithAutoRefresh(
                .getAIInsights(period: period)
            )
            guard !Task.isCancelled else { return }
            guard selectedPeriod == period else {
                isLoading = false
                return
            }
            insights = result
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }
}
