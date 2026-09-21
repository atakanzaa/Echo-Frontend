import SwiftUI

struct JournalCalendarView: View {
    @Bindable var model: JournalCalendarViewModel
    let timeZone: TimeZone
    let onEntryTap: (String) -> Void

    @Environment(\.locale) private var locale

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.space.xxxs), count: 7)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.space.md) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) {
                            Task { await model.loadMonth() }
                        }
                    })
                }
                monthHeader
                weekdayHeader
                calendarGrid
                if let month = model.calendarMonth {
                    monthSummary(month)
                }
                selectedDayEntries
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .echoRefreshable { await model.refresh() }
        .task { await model.refresh() }
    }

    private var monthHeader: some View {
        HStack {
            EchoIconButton("chevron.left", accessibilityTitle: "calendar.previousMonth") {
                Task { await model.moveMonth(by: -1) }
            }
            Spacer()
            Text(JournalPresentation.monthTitle(year: model.year, month: model.month, locale: locale))
                .echoTextStyle(.title3)
                .foregroundStyle(AppTheme.color.content.primary)
            Spacer()
            EchoIconButton("chevron.right", accessibilityTitle: "calendar.nextMonth") {
                Task { await model.moveMonth(by: 1) }
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.space.xxxs) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .echoTextStyle(.caption2)
                    .foregroundStyle(AppTheme.color.content.tertiary)
                    .frame(maxWidth: .infinity, minHeight: AppTheme.layout.minTouchTarget)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder private var calendarGrid: some View {
        if model.isLoadingMonth, model.calendarMonth == nil {
            ProgressView().frame(maxWidth: .infinity, minHeight: 220)
        } else {
            LazyVGrid(columns: columns, spacing: AppTheme.space.xxxs) {
                ForEach(0..<leadingBlankCount, id: \.self) { _ in
                    Color.clear.frame(minHeight: AppTheme.layout.minTouchTarget)
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let data = model.calendarMonth?.days.first { $0.day == day }
        let isSelected = model.selectedDay?.day == day
            && model.selectedDay?.month == model.month
            && model.selectedDay?.year == model.year
        let isToday = model.calendarMonth?.today == LocalDay(year: model.year, month: model.month, day: day)
        return Button {
            Task { await model.select(day: day) }
        } label: {
            VStack(spacing: AppTheme.space.xxxs) {
                Text(day, format: .number)
                    .echoTextStyle((data?.entryCount ?? 0) > 0 ? .bodyEmphasis : .body)
                    .foregroundStyle(isSelected ? AppTheme.color.content.onAccent : AppTheme.color.content.primary)
                HStack(spacing: AppTheme.space.xxxxs) {
                    if let category = data?.moodCategory {
                        EchoMoodGlyph(level: category.displayLevel, size: 8)
                    }
                    if data?.hasCoachSession == true {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(isSelected ? AppTheme.color.content.onAccent : AppTheme.color.content.accent)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Circle().fill(isSelected ? AppTheme.color.accent.primary : .clear))
            .overlay {
                if isToday, !isSelected {
                    Circle().strokeBorder(AppTheme.color.border.accent, lineWidth: 1)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(day)"))
        .accessibilityValue(data?.moodLabel ?? "")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func monthSummary(_ month: CalendarMonth) -> some View {
        EchoCard(style: .flat) {
            HStack(spacing: AppTheme.space.sm) {
                metric(value: "\(month.activeDays)", label: "calendar.activeDays")
                Rectangle().fill(AppTheme.color.border.subtle).frame(width: 1, height: AppTheme.space.xxl)
                metric(value: "\(month.totalEntries)", label: "calendar.entries")
                if let average = month.averageMood {
                    Rectangle().fill(AppTheme.color.border.subtle).frame(width: 1, height: AppTheme.space.xxl)
                    metric(value: average.formatted(.number.precision(.fractionLength(1))), label: "calendar.averageMood")
                }
            }
        }
    }

    private func metric(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: AppTheme.space.xxxs) {
            Text(value).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
            Text(label).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var selectedDayEntries: some View {
        if let day = model.selectedDay {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                Text(JournalPresentation.dayTitle(day, locale: locale, timeZone: timeZone))
                    .echoTextStyle(.caption2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppTheme.color.content.tertiary)
                    .accessibilityAddTraits(.isHeader)
                if model.dayEntries.isEmpty, !model.isLoadingDay {
                    EchoEmptyState("calendar.dayEmpty", message: "calendar.dayEmptyMessage", systemImage: "calendar.badge.minus")
                } else {
                    ForEach(model.dayEntries) { entry in
                        EchoEntryCard(model: JournalPresentation.cardModel(for: entry), onTap: { onEntryTap(entry.id) })
                            .task {
                                if entry.id == model.dayEntries.last?.id { await model.loadNextDayPage() }
                            }
                    }
                    if model.isLoadingDay { ProgressView().frame(maxWidth: .infinity) }
                }
            }
        }
    }

    private var configuredCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = timeZone
        return calendar
    }

    private var firstDate: Date? {
        configuredCalendar.date(from: DateComponents(year: model.year, month: model.month, day: 1))
    }

    private var daysInMonth: Int {
        guard let firstDate else { return 30 }
        return configuredCalendar.range(of: .day, in: .month, for: firstDate)?.count ?? 30
    }

    private var leadingBlankCount: Int {
        guard let firstDate else { return 0 }
        let weekday = configuredCalendar.component(.weekday, from: firstDate)
        return (weekday - configuredCalendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = configuredCalendar.veryShortStandaloneWeekdaySymbols
        let start = max(0, configuredCalendar.firstWeekday - 1)
        return Array(symbols[start...] + symbols[..<start])
    }
}
