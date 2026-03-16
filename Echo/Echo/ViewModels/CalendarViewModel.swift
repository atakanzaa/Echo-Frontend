import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {

    @Published var calendarData: APICalendarMonth?
    @Published var currentDate  = Date()
    @Published var selectedDay: Int?
    @Published var selectedEntry: APIJournalEntry?
    @Published var isLoading    = false
    @Published var errorMessage: String?

    var displayMonthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: currentDate)
    }

    var year:  Int { Calendar.current.component(.year,  from: currentDate) }
    var month: Int { Calendar.current.component(.month, from: currentDate) }

    func loadMonth() {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let data: APICalendarMonth = try await APIClient.shared.requestWithAutoRefresh(
                    .getCalendarMonth(year: year, month: month)
                )
                calendarData = data
                isLoading    = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func nextMonth() {
        if let d = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = d
            selectedDay = nil
            loadMonth()
        }
    }

    func prevMonth() {
        if let d = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = d
            selectedDay = nil
            loadMonth()
        }
    }

    func selectDay(_ day: Int) {
        selectedDay = day
        guard let calendarData else { return }
        if let apiDay = calendarData.days.first(where: { $0.day == day }),
           let entryId = apiDay.entryId {
            Task {
                do {
                    let entry: APIJournalEntry = try await APIClient.shared.requestWithAutoRefresh(
                        .getJournalEntry(id: entryId)
                    )
                    selectedEntry = entry
                } catch {
                    // entry yüklenemezse sessizce geç
                }
            }
        } else {
            selectedEntry = nil
        }
    }

    /// APICalendarDay.moodLabel → EmotionalState (backend: very_positive/positive/neutral/negative/very_negative)
    func emotionalState(for day: APICalendarDay) -> EmotionalState {
        guard let label = day.moodLabel else { return .empty }
        switch label.lowercased() {
        case "very_positive", "motivated": return .motivated
        case "positive", "calm":           return .calm
        case "negative", "very_negative", "stressed", "stress": return .stress
        case "mixed":     return .mixed
        case "neutral":   return .neutral
        default:          return .empty
        }
    }
}
