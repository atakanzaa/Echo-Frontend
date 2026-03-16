import Foundation
import Combine

@MainActor
final class JournalViewModel: ObservableObject {

    @Published var entries:      [APIJournalEntry] = []
    @Published var isLoading     = false
    @Published var errorMessage: String?

    func loadRecent(limit: Int = 20) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result: [APIJournalEntry] = try await APIClient.shared.requestWithAutoRefresh(
                    .getRecentJournalEntries(limit: limit)
                )
                entries   = result
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func loadByDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let result: [APIJournalEntry] = try await APIClient.shared.requestWithAutoRefresh(
                    .getJournalEntriesByDate(date: dateStr)
                )
                entries   = result
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }
}

// MARK: — Helpers

extension APIJournalEntry {

    /// "Today", "Yesterday", "2 days ago" veya kısa tarih
    var relativeDate: String {
        guard let date = ISO8601DateFormatter().date(from: recordedAt) else { return entryDate }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        case 2:  return "2 days ago"
        default:
            let f = DateFormatter()
            f.dateStyle = .medium
            return f.string(from: date)
        }
    }

    /// audioDurationSeconds → "4m 12s"
    var formattedDuration: String {
        guard let sec = audioDurationSeconds, sec > 0 else { return "" }
        let m = sec / 60
        let s = sec % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    /// moodLabel → EmotionalState (backend: very_positive/positive/neutral/negative/very_negative)
    var emotionalState: EmotionalState {
        switch analysis?.moodLabel?.lowercased() {
        case "very_positive", "motivated": return .motivated
        case "positive", "calm":           return .calm
        case "negative", "very_negative", "stressed", "stress": return .stress
        case "mixed":     return .mixed
        case "neutral":   return .neutral
        default:          return .neutral
        }
    }
}
