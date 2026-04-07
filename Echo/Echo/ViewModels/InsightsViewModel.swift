import Foundation
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {

    @Published var summary:      APISummaryResponse?
    @Published var isLoading     = false
    @Published var errorMessage: String?

    // MARK: — Gerçek veri bazlı haftalık mood scores (placeholder kaldırıldı)

    /// Son 7 girişin mood score'ları (0-10 skalasına çevrilmiş)
    var weeklyScores: [Double] {
        guard let scores = summary?.dailyMoodScores, !scores.isEmpty else { return [] }
        return scores.suffix(7).map { $0.moodScore * 10 }
    }

    /// Haftalık chart için gün etiketleri (gerçek tarihlerden)
    var weeklyDayLabels: [String] {
        guard let scores = summary?.dailyMoodScores, !scores.isEmpty else { return [] }
        return scores.suffix(7).compactMap { DateFormatting.weekdayAbbreviation(from: $0.date) }
    }

    var totalEntriesText: String { summary.map { "\($0.recordedDays)" } ?? "—" }

    /// Mood score: backend 0-1 skalası → frontend 0-10 skalası olarak gösterir
    var avgMoodText: String { summary.map { String(format: "%.1f", $0.averageMoodScore * 10) } ?? "—" }

    /// Gerçek veri bazlı emotion distribution (dailyMoodScores moodLabel sayımlarından)
    var emotionStats: [(emotion: EmotionalState, label: String, percentage: Int)] {
        guard let scores = summary?.dailyMoodScores, !scores.isEmpty else { return [] }

        // moodLabel'lara göre say
        var labelCounts: [String: Int] = [:]
        for score in scores {
            let label = score.moodLabel ?? "neutral"
            labelCounts[label, default: 0] += 1
        }

        let total = scores.count
        return labelCounts
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map { key, count in
                let pct = Int(Double(count) / Double(total) * 100)
                return (emotionFromName(key), key.capitalized, max(pct, 1))
            }
    }

    func loadSummary(period: Int = 30) {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let result: APISummaryResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .getSummary(period: period, endDate: nil)
                )
                summary   = result
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    /// Mood label → EmotionalState eşlemesi (İngilizce + Türkçe destekli)
    private func emotionFromName(_ name: String) -> EmotionalState {
        switch name.lowercased() {
        // İngilizce
        case let n where n.contains("stress") || n.contains("anxi") || n.contains("negative") || n.contains("very_negative"):
            return .stress
        case let n where n.contains("calm") || n.contains("peace") || n.contains("positive"):
            return .calm
        case let n where n.contains("motiv") || n.contains("energy") || n.contains("very_positive"):
            return .motivated
        case let n where n.contains("mix"):
            return .neutral
        // Türkçe
        case let n where n.contains("stres") || n.contains("kayg") || n.contains("gergin") || n.contains("üzg"):
            return .stress
        case let n where n.contains("huzur") || n.contains("sakin") || n.contains("mutlu") || n.contains("olumlu"):
            return .calm
        case let n where n.contains("motiv") || n.contains("enerj") || n.contains("heyecan") || n.contains("coşku"):
            return .motivated
        case let n where n.contains("karış") || n.contains("karmas"):
            return .neutral
        default:
            return .neutral
        }
    }
}
