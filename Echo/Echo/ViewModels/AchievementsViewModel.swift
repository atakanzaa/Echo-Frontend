import Foundation
import Combine

@MainActor
final class AchievementsViewModel: ObservableObject {

    @Published var data:         APIAchievementsResponse?
    @Published var isLoading     = false
    @Published var errorMessage: String?
    private let loadTask = TaskGuard()

    var currentStreak: Int    { data?.currentStreak ?? 0 }
    var longestStreak: Int    { data?.longestStreak  ?? 0 }
    var totalEntries:  Int    { data?.totalEntries   ?? 0 }
    var level:         String { data?.level          ?? "" }
    var levelMessage:  String { data?.levelMessage   ?? "" }
    var badges:        [APIBadge] { data?.badges     ?? [] }

    var insightScoreText: String {
        guard let d = data else { return "—%" }
        return "\(Int(d.insightScore))%"
    }

    var totalWordsText: String {
        guard let d = data else { return "—" }
        return d.totalWords >= 1000 ? String(format: "%.1fk", Double(d.totalWords) / 1000) : "\(d.totalWords)"
    }

    var streakMessage: String {
        let streak = currentStreak
        switch streak {
        case 0:       return "Start your streak today!"
        case 1...3:   return "Great start! Keep going 🔥"
        case 4...6:   return "You're building momentum!"
        case 7...13:  return "You're on fire! 🔥"
        case 14...29: return "Incredible dedication! 💪"
        default:      return "Legendary journaler! 👑"
        }
    }

    func load() {
        loadTask.run { [weak self] in
            await self?.performLoad()
        }
    }

    func refresh() async {
        await loadTask.runAsync { [weak self] in
            await self?.performLoad()
        }
    }

    func cancelAll() {
        loadTask.cancel()
    }

    private func performLoad() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: APIAchievementsResponse = try await APIClient.shared.requestWithAutoRefresh(
                .getAchievements
            )
            guard !Task.isCancelled else { return }
            data = result
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }
}
