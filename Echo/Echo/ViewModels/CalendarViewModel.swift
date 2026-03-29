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

    /// Maps APICalendarDay to EmotionalState using backend moodCategory (primary) or moodScore (fallback).
    func emotionalState(for day: APICalendarDay) -> EmotionalState {
        guard day.entryId != nil else { return .empty }
        if let category = day.moodCategory {
            switch category {
            case "STRESS":    return .stress
            case "NEUTRAL":   return .neutral
            case "CALM":      return .calm
            case "MOTIVATED": return .motivated
            default: break
            }
        }
        // Fallback: score-range if moodCategory absent
        guard let score = day.moodScore else { return .empty }
        switch score {
        case 0..<0.25:    return .stress
        case 0.25..<0.50: return .neutral
        case 0.50..<0.75: return .calm
        default:          return .motivated
        }
    }
}
