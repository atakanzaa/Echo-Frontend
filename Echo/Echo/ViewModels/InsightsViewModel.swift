import Foundation
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {

    @Published var summary:      APISummaryResponse?
    @Published var isLoading     = false
    @Published var errorMessage: String?
    private let summaryTask = TaskGuard()

    // MARK: — Gerçek veri bazlı haftalık mood scores (placeholder kaldırıldı)

    /// Son 7 girişin mood score'ları (0-10 skalasına çevrilmiş)
    var weeklyScores: [Double] {
        guard let scores = summary?.dailyMoodScores, !scores.isEmpty else { return [] }
        return scores.suffix(7).map { $0.moodScore * 10 }
    }

    /// Haftalık chart için gün etiketleri (gerçek tarihlerden)
    var weeklyDayLabels: [String] {
        guard let scores = summary?.dailyMoodScores, !scores.isEmpty else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        dayFormatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "tr" ? "tr_TR" : "en_US")
        return scores.suffix(7).compactMap { score in
            formatter.date(from: score.date).map { dayFormatter.string(from: $0) }
        }
    }

    var totalEntriesText: String { summary.map { "\($0.recordedDays)" } ?? "—" }

    /// Mood score: backend 0-1 skalası → frontend 0-10 skalası olarak gösterir
    var avgMoodText: String { summary.map { String(format: "%.1f", $0.averageMoodScore * 10) } ?? "—" }

    var emotionStats: [(emotion: EmotionalState, label: String, percentage: Int, count: Int)] {
        guard let dist = summary?.moodCategoryDistribution, !dist.isEmpty else { return [] }
        guard let scores = summary?.dailyMoodScores, !scores.isEmpty else { return [] }
        let total = scores.count

        let order: [(key: String, state: EmotionalState)] = [
            ("STRESS", .stress),
            ("NEUTRAL", .neutral),
            ("CALM", .calm),
            ("MOTIVATED", .motivated)
        ]

        var raw: [(emotion: EmotionalState, label: String, pct: Double, count: Int)] = []
        for item in order {
            guard let pct = dist[item.key], pct > 0 else { continue }
            let count = Int((Double(total) * pct / 100.0).rounded())
            raw.append((emotion: item.state, label: item.key.capitalized, pct: pct, count: max(count, 1)))
        }

        guard !raw.isEmpty else { return [] }

        var percents = raw.map { Int($0.pct.rounded()) }
        let diff = 100 - percents.reduce(0, +)
        if diff != 0, let targetIndex = raw.indices.max(by: { raw[$0].pct < raw[$1].pct }) {
            percents[targetIndex] += diff
        }

        return raw.enumerated().map { idx, item in
            (item.emotion, item.label, max(0, percents[idx]), item.count)
        }
    }

    func loadSummary(period: Int = 30) {
        summaryTask.run { [weak self] in
            await self?.performLoadSummary(period: period)
        }
    }

    func refresh(period: Int = 30) async {
        await summaryTask.runAsync { [weak self] in
            await self?.performLoadSummary(period: period)
        }
    }

    func cancelAll() {
        summaryTask.cancel()
    }

    private func performLoadSummary(period: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let result: APISummaryResponse = try await APIClient.shared.requestWithAutoRefresh(
                .getSummary(period: period, endDate: nil)
            )
            guard !Task.isCancelled else { return }
            summary = result
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }
}
