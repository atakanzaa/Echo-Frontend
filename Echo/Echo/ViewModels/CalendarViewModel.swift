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
    private let monthTask = TaskGuard()
    private let dayEntryTask = TaskGuard()

    var displayMonthYear: String {
        DateFormatting.monthYear(from: currentDate)
    }

    var year:  Int { Calendar.current.component(.year,  from: currentDate) }
    var month: Int { Calendar.current.component(.month, from: currentDate) }

    func loadMonth() {
        let requestYear = year
        let requestMonth = month
        monthTask.run { [weak self] in
            await self?.performLoadMonth(year: requestYear, month: requestMonth)
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
            dayEntryTask.run { [weak self] in
                await self?.performSelectDay(entryId: entryId, day: day)
            }
        } else {
            selectedEntry = nil
        }
    }

    func refresh() async {
        let requestYear = year
        let requestMonth = month
        await monthTask.runAsync { [weak self] in
            await self?.performLoadMonth(year: requestYear, month: requestMonth)
        }
    }

    func cancelAll() {
        monthTask.cancel()
        dayEntryTask.cancel()
    }

    /// Maps APICalendarDay to EmotionalState using backend moodCategory (primary) or moodScore (fallback).
    func emotionalState(for day: APICalendarDay) -> EmotionalState {
        guard day.entryId != nil else { return .empty }
        if let category = day.resolvedMoodCategory {
            switch category {
            case .stress:    return .stress
            case .neutral:   return .neutral
            case .calm:      return .calm
            case .motivated: return .motivated
            case .unknown:   break
            }
        }
        guard let score = day.moodScore else { return .empty }
        switch score {
        case 0..<0.25:    return .stress
        case 0.25..<0.50: return .neutral
        case 0.50..<0.75: return .calm
        default:          return .motivated
        }
    }

    private func performLoadMonth(year: Int, month: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let data: APICalendarMonth = try await APIClient.shared.requestWithAutoRefresh(
                .getCalendarMonth(year: year, month: month)
            )
            guard !Task.isCancelled else { return }
            guard self.year == year, self.month == month else {
                isLoading = false
                return
            }
            calendarData = data
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }

    private func performSelectDay(entryId: String, day: Int) async {
        do {
            let entry: APIJournalEntry = try await APIClient.shared.requestWithAutoRefresh(
                .getJournalEntry(id: entryId)
            )
            guard !Task.isCancelled else { return }
            guard selectedDay == day else { return }
            selectedEntry = entry
        } catch {
            // entry yüklenemezse sessizce geç
        }
    }
}
