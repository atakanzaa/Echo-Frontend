import Foundation
import Combine

@MainActor
final class JournalViewModel: ObservableObject {

    @Published var entries:      [APIJournalEntry] = []
    @Published var isLoading     = false
    @Published var errorMessage: String?
    private let loadTask = TaskGuard()

    func loadRecent(limit: Int = 20) {
        loadTask.run { [weak self] in
            await self?.performLoadRecent(limit: limit)
        }
    }

    func loadByDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        loadTask.run { [weak self] in
            await self?.performLoadByDate(dateStr)
        }
    }

    func refresh() async {
        await loadTask.runAsync { [weak self] in
            await self?.performLoadRecent(limit: 20)
        }
    }

    func cancelAll() {
        loadTask.cancel()
    }

    private func performLoadRecent(limit: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [APIJournalEntry] = try await APIClient.shared.requestWithAutoRefresh(
                .getRecentJournalEntries(limit: limit)
            )
            guard !Task.isCancelled else { return }
            entries = result
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }

    private func performLoadByDate(_ dateStr: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [APIJournalEntry] = try await APIClient.shared.requestWithAutoRefresh(
                .getJournalEntriesByDate(date: dateStr)
            )
            guard !Task.isCancelled else { return }
            entries = result
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: — Helpers

extension APIJournalEntry {

    /// "Today", "Yesterday", "2 days ago" veya kısa tarih
    var relativeDate: String {
        guard let date = ISO8601DateFormatter().date(from: recordedAt) else { return entryDate }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        let loc = LocalizationManager.shared
        switch days {
        case 0:  return loc.t("common.today")
        case 1:  return loc.t("common.yesterday")
        case 2:  return String(format: loc.t("common.relative.days_ago_fmt"), 2)
        default:
            let f = DateFormatter()
            f.dateStyle = .medium
            return f.string(from: date)
        }
    }

    /// recordedAt → "SEP 22, 10:45 AM"
    var formattedDatetime: String {
        guard let date = ISO8601DateFormatter().date(from: recordedAt) else { return entryDate }
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: date).uppercased()
    }

    /// audioDurationSeconds → "4m 12s"
    var formattedDuration: String {
        guard let sec = audioDurationSeconds, sec > 0 else { return "" }
        let m = sec / 60
        let s = sec % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    /// moodCategory (primary) or moodScore-range (fallback) → EmotionalState
    var emotionalState: EmotionalState {
        if let category = analysis?.moodCategory {
            switch category {
            case "STRESS":    return .stress
            case "NEUTRAL":   return .neutral
            case "CALM":      return .calm
            case "MOTIVATED": return .motivated
            default: break
            }
        }
        guard let score = analysis?.moodScore else { return .neutral }
        switch score {
        case 0..<0.25:    return .stress
        case 0.25..<0.50: return .neutral
        case 0.50..<0.75: return .calm
        default:          return .motivated
        }
    }

    var statusLocalizationKey: String? {
        switch status.lowercased() {
        case "complete", "completed", "done", "success":
            return "journal.status.complete"
        case "failed", "error":
            return "journal.status.failed"
        case "processing", "pending", "queued", "analyzing", "transcribing", "uploading", "uploaded", "in_progress", "in-progress":
            return "journal.status.processing"
        default:
            return nil
        }
    }

    var humanizedStatus: String {
        status
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

extension APIAnalysisResult {
    var moodLocalizationKey: String {
        if let category = moodCategory?.uppercased() {
            switch category {
            case "STRESS": return "calendar.emotion.stress"
            case "NEUTRAL": return "calendar.emotion.neutral"
            case "CALM": return "calendar.emotion.calm"
            case "MOTIVATED": return "calendar.emotion.motivated"
            default: break
            }
        }

        let normalized = (moodLabel ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case "stress", "stressed", "negative", "slightly_negative", "very_negative", "anxious", "sad", "low":
            return "calendar.emotion.stress"
        case "neutral", "slightly_neutral", "mixed":
            return "calendar.emotion.neutral"
        case "calm", "positive", "slightly_positive", "very_positive", "peaceful", "happy":
            return "calendar.emotion.calm"
        case "motivated", "motivation", "energetic", "high":
            return "calendar.emotion.motivated"
        default:
            return "calendar.emotion.neutral"
        }
    }
}
