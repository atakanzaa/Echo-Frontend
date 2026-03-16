import Foundation
import Combine

@MainActor
final class AIInsightsViewModel: ObservableObject {

    @Published var insights:      APIAIInsightsResponse?
    @Published var selectedPeriod = 7
    @Published var isLoading      = false
    @Published var errorMessage:  String?

    let periodOptions: [(label: String, days: Int)] = [
        ("Last 7 Days",  7),
        ("Last 30 Days", 30),
        ("Last 90 Days", 90)
    ]

    var moodPercentText: String {
        guard let i = insights else { return "—%" }
        return "\(Int(i.moodScore * 10))%"
    }

    var trendText: String {
        guard let i = insights else { return "" }
        let sign = i.emotionalTrend >= 0 ? "+" : ""
        return "\(sign)\(Int(i.emotionalTrend))%"
    }

    var isTrendPositive: Bool { (insights?.emotionalTrend ?? 0) >= 0 }

    func loadInsights() {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let result: APIAIInsightsResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .getAIInsights(period: selectedPeriod)
                )
                insights  = result
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func selectPeriod(_ days: Int) {
        selectedPeriod = days
        loadInsights()
    }
}
