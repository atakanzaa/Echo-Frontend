import Foundation
import Observation

@Observable
@MainActor
final class JournalCalendarViewModel {
    private(set) var year: Int
    private(set) var month: Int
    private(set) var calendarMonth: CalendarMonth?
    private(set) var selectedDay: LocalDay?
    private(set) var dayEntries: [JournalEntry] = []
    private(set) var isLoadingMonth = false
    private(set) var isLoadingDay = false
    private(set) var hasMoreDayEntries = false
    private(set) var error: AppError?

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private let insights: any InsightsServicing
    @ObservationIgnored private var dayCursor: String?
    @ObservationIgnored private var alignedToBackendToday = false

    init(journal: any JournalServicing, insights: any InsightsServicing, timeZone: TimeZone) {
        self.journal = journal
        self.insights = insights
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month], from: Date())
        year = components.year ?? 2000
        month = components.month ?? 1
    }

    func loadMonth() async {
        await loadMonth(alignToToday: !alignedToBackendToday)
    }

    /// Seçili günün kayıtları boşaltılmaz; ilk sayfa gelince yerine konur.
    func refresh() async {
        await loadMonth()
        guard let day = selectedDay else { return }
        do {
            let page = try await journal.entries(day: day, cursor: nil, size: 20)
            guard selectedDay == day else { return }
            dayEntries = page.items
            dayCursor = page.nextCursor
            hasMoreDayEntries = page.hasMore && page.nextCursor != nil
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func moveMonth(by offset: Int) async {
        var nextYear = year
        var nextMonth = month + offset
        while nextMonth < 1 { nextMonth += 12; nextYear -= 1 }
        while nextMonth > 12 { nextMonth -= 12; nextYear += 1 }
        year = nextYear
        month = nextMonth
        selectedDay = nil
        dayEntries = []
        dayCursor = nil
        hasMoreDayEntries = false
        await loadMonth(alignToToday: false)
    }

    func select(day: Int) async {
        let selection = LocalDay(year: year, month: month, day: day)
        guard selectedDay != selection else { return }
        selectedDay = selection
        dayEntries = []
        dayCursor = nil
        hasMoreDayEntries = true
        await loadNextDayPage()
    }

    func loadNextDayPage() async {
        guard let selectedDay, !isLoadingDay, hasMoreDayEntries else { return }
        isLoadingDay = true
        error = nil
        defer { isLoadingDay = false }
        do {
            let page = try await journal.entries(day: selectedDay, cursor: dayCursor, size: 20)
            dayEntries.append(contentsOf: page.items)
            dayCursor = page.nextCursor
            hasMoreDayEntries = page.hasMore && page.nextCursor != nil
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    private func loadMonth(alignToToday: Bool) async {
        guard !isLoadingMonth else { return }
        isLoadingMonth = true
        error = nil
        do {
            let response = try await insights.calendar(year: year, month: month)
            isLoadingMonth = false
            if alignToToday, let today = response.today,
               today.year != response.year || today.month != response.month {
                alignedToBackendToday = true
                year = today.year
                month = today.month
                await loadMonth(alignToToday: false)
                return
            }
            alignedToBackendToday = true
            calendarMonth = response
            if selectedDay == nil, let today = response.today,
               today.year == response.year, today.month == response.month {
                await select(day: today.day)
            }
        } catch {
            isLoadingMonth = false
            self.error = AppError.displayable(error)
        }
    }
}
