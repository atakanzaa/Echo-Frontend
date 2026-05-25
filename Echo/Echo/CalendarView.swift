import SwiftUI

struct EmotionalHeatmapCalendarView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = CalendarViewModel()
    @State private var isMenuOpen = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        NavigationStack {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.calendar"),
                    showMenu: true,
                    onMenu: { isMenuOpen.toggle() }
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Month Selector
                        HStack(spacing: AppTheme.Spacing.md) {
                            Button(action: { viewModel.prevMonth() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    .frame(width: 32, height: 32)
                                    .background(AppTheme.Colors.surface(colorScheme))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Text(viewModel.displayMonthYear)
                                .font(AppTheme.Typography.heading2)
                                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                            Spacer()
                            Button(action: { viewModel.nextMonth() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    .frame(width: 32, height: 32)
                                    .background(AppTheme.Colors.surface(colorScheme))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Month Summary Bar
                        if let summary = viewModel.calendarData?.monthSummary {
                            HStack(spacing: AppTheme.Spacing.md) {
                                if let avg = summary.averageMood {
                                    CalendarStatPill(
                                        icon: "face.smiling",
                                        value: String(format: "%.1f", avg * 10),
                                        label: locManager.t("calendar.avg_mood")
                                    )
                                }
                                CalendarStatPill(
                                    icon: "doc.text",
                                    value: "\(summary.totalEntries)",
                                    label: locManager.t("calendar.entries")
                                )
                                CalendarStatPill(
                                    icon: "flame",
                                    value: "\(summary.streakDays)",
                                    label: locManager.t("calendar.active_days")
                                )
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                                .padding()
                        } else if let error = viewModel.errorMessage, viewModel.calendarData == nil {
                            ErrorStateView(message: error) {
                                viewModel.loadMonth()
                            }
                        } else if let calData = viewModel.calendarData {
                            // Calendar Grid
                            APICalendarGridView(
                                calendarData: calData,
                                selectedDay: $viewModel.selectedDay,
                                onSelectDay: { viewModel.selectDay($0) },
                                emotionalState: { viewModel.emotionalState(for: $0) }
                            )
                            // Legend
                            LegendView()
                            // Day Details
                            if let entry = viewModel.selectedEntry {
                                APISelectedDayView(entry: entry, selectedTab: $selectedTab)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .padding(.bottom, AppTheme.Spacing.md)
                            }
                        } else {
                            EmptyStateView(
                                icon: "calendar",
                                title: locManager.t("nav.calendar"),
                                subtitle: locManager.t("calendar.no_entry_for_day")
                            )
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.md)
                }
                .refreshable {
                    await viewModel.refresh()
                }

            }

            // Hamburger Menu Overlay
            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .onAppear { viewModel.loadMonth() }
        .onDisappear { viewModel.cancelAll() }
        }
    }
}

typealias CalendarView = EmotionalHeatmapCalendarView

// MARK: - API Calendar Grid

struct APICalendarGridView: View {
    let calendarData: APICalendarMonth
    @Binding var selectedDay: Int?
    let onSelectDay: (Int) -> Void
    let emotionalState: (APICalendarDay) -> EmotionalState
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let dayKeys = ["calendar.day.sun", "calendar.day.mon", "calendar.day.tue", "calendar.day.wed", "calendar.day.thu", "calendar.day.fri", "calendar.day.sat"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                ForEach(dayKeys, id: \.self) { key in
                    Text(locManager.t(key))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
                ForEach(calendarData.days, id: \.day) { apiDay in
                    let isToday = Calendar.current.isDate(
                        Calendar.current.date(from: DateComponents(year: calendarData.year, month: calendarData.month, day: apiDay.day)) ?? Date(),
                        inSameDayAs: Date()
                    )
                    DayButtonView(
                        day: apiDay.day,
                        emotion: emotionalState(apiDay),
                        isSelected: selectedDay == apiDay.day,
                        isToday: isToday,
                        entryCount: apiDay.entryCount ?? (apiDay.entryId != nil ? 1 : 0),
                        hasCoachSession: apiDay.hasCoachSession ?? false,
                        action: { onSelectDay(apiDay.day) }
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
    }
}

// MARK: - API Selected Day Details

struct APISelectedDayView: View {
    let entry: APIJournalEntry
    @Binding var selectedTab: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: entry.recordedAt) else { return entry.entryDate }
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM"
        f.locale = Locale(identifier: locManager.currentLanguage == "tr" ? "tr_TR" : "en_US")
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header: date, duration, mood badge + score
            HStack(spacing: AppTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    if !entry.formattedDuration.isEmpty {
                        Text("\(entry.formattedDuration) \(locManager.t("calendar.audio"))")
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    }
                }
                Spacer()
                if let analysis = entry.analysis {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(entry.emotionalState.color)
                                .frame(width: 8, height: 8)
                            Text(locManager.t(analysis.moodLocalizationKey).uppercased(with: Locale(identifier: locManager.currentLanguage == "tr" ? "tr_TR" : "en_US")))
                                .font(AppTheme.Typography.micro).fontWeight(.bold)
                                .tracking(0.5)
                                .foregroundColor(entry.emotionalState.color)
                        }
                        if let score = analysis.moodScore {
                            Text(String(format: "%.1f/10", score * 10))
                                .font(AppTheme.Typography.micro)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(entry.emotionalState.color.opacity(0.15))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
                }
            }

            // Key Emotions chips
            if let emotions = entry.analysis?.keyEmotions, !emotions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(emotions.prefix(4), id: \.self) { emotion in
                            Text(emotion)
                                .font(AppTheme.Typography.micro).fontWeight(.semibold)
                                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.9))
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(AppTheme.Colors.accentSoft(colorScheme))
                                .cornerRadius(AppTheme.Spacing.radiusSm)
                        }
                    }
                }
            }

            if let analysis = entry.analysis {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.accent.opacity(0.8))
                        Text(locManager.t("calendar.ai_summary"))
                            .font(AppTheme.Typography.label).fontWeight(.bold)
                            .tracking(0.6)
                            .foregroundColor(AppTheme.Colors.accent.opacity(0.8))
                    }
                    Text(analysis.summary ?? "")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                        .lineSpacing(2)
                }
                .padding(17)
                .background(AppTheme.Colors.background(colorScheme).opacity(0.5))
                .cornerRadius(AppTheme.Spacing.radiusXl)

                if let question = analysis.reflectiveQuestion, !question.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(locManager.t("calendar.reflection_question"))
                            .font(AppTheme.Typography.micro).fontWeight(.bold)
                            .tracking(0.6)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(question)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                        }
                    }
                }
            }

            // Detail button
            NavigationLink(destination: JournalDetailView(entry: entry, selectedTab: $selectedTab)) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(AppTheme.Typography.caption)
                    Text(locManager.t("calendar.view_details"))
                        .font(AppTheme.Typography.caption).fontWeight(.semibold)
                }
                .foregroundColor(AppTheme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.Colors.accentSoft(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.Spacing.lg - 1)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusXl)
    }
}

// MARK: - Supporting Types

// 4 score-range categories + empty (no entry)
// 0.00-0.25 → stress | 0.25-0.50 → neutral | 0.50-0.75 → calm | 0.75-1.00 → motivated
enum EmotionalState {
    case stress, neutral, calm, motivated, empty

    var color: Color {
        switch self {
        case .stress:    return AppTheme.Colors.destructive
        case .neutral:   return Color(red: 0.612, green: 0.639, blue: 0.686)
        case .calm:      return Color(red: 0.235, green: 0.808, blue: 0.996)
        case .motivated: return AppTheme.Colors.success
        case .empty:     return Color.clear
        }
    }

    var label: String {
        switch self {
        case .stress:    return "calendar.emotion.stress"
        case .neutral:   return "calendar.emotion.neutral"
        case .calm:      return "calendar.emotion.calm"
        case .motivated: return "calendar.emotion.motivated"
        case .empty:     return ""
        }
    }

    var emoji: String {
        switch self {
        case .stress:    return "😔"
        case .neutral:   return "😌"
        case .calm:      return "🌿"
        case .motivated: return "⚡️"
        case .empty:     return "📓"
        }
    }
}

struct DayButtonView: View {
    let day: Int
    let emotion: EmotionalState
    let isSelected: Bool
    let isToday: Bool
    var entryCount: Int = 0
    var hasCoachSession: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var hasEntry: Bool { emotion != .empty }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 15, weight: hasEntry || isToday ? .semibold : .regular))
                    .foregroundColor(isToday ? AppTheme.Colors.accent : (hasEntry ? AppTheme.Colors.textPrimary(colorScheme) : AppTheme.Colors.textMuted(colorScheme)))

                // Mood dot row — mood + optional coach indicator
                HStack(spacing: 3) {
                    if hasEntry {
                        Circle()
                            .fill(emotion.color)
                            .frame(width: 6, height: 6)
                    } else if isToday {
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .frame(width: 6, height: 6)
                            .opacity(0)
                    }

                    if hasCoachSession {
                        Circle()
                            .fill(AppTheme.Colors.gold)
                            .frame(width: 4, height: 4)
                    }
                }

                // Multiple entries indicator
                if entryCount > 1 {
                    Text("\(entryCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                    .fill(isSelected ? AppTheme.Colors.surface(colorScheme) : (isToday ? AppTheme.Colors.accentSoft(colorScheme).opacity(0.5) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                    .stroke(isSelected ? AppTheme.Colors.border(colorScheme) : (isToday ? AppTheme.Colors.accent.opacity(0.3) : Color.clear), lineWidth: 1.5)
            )
        }
    }
}

struct LegendView: View {
    private let legends: [(EmotionalState, String)] = [
        (.stress, "calendar.emotion.stress"), (.neutral, "calendar.emotion.neutral"), (.calm, "calendar.emotion.calm"), (.motivated, "calendar.emotion.motivated")
    ]
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(legends, id: \.1) { state, label in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(state.color)
                            .frame(width: 8, height: 8)
                        Text(locManager.t(label))
                            .font(AppTheme.Typography.micro)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

// MARK: - Calendar Stat Pill

struct CalendarStatPill: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.accent)
                Text(value)
                    .font(AppTheme.Typography.bodyEm)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
            Text(label)
                .font(AppTheme.Typography.micro)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusMd)
    }
}

struct BottomNavigationView: View {
    let currentPage: String
    @Binding var selectedTab: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    private static let items: [(icon: String, label: String, tab: String)] = [
        ("book.fill",      "nav.journal",  "journal"),
        ("calendar",       "nav.calendar", "calendar"),
        ("chart.bar.fill", "nav.insights", "insights"),
        ("gear",           "nav.settings", "settings")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(AppTheme.Colors.border(colorScheme))
            HStack(spacing: 0) {
                ForEach(Self.items, id: \.tab) { item in
                    Button(action: { selectedTab = item.tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(item.tab == currentPage
                                    ? AppTheme.Colors.textPrimary(colorScheme)
                                    : AppTheme.Colors.textMuted(colorScheme))
                            Text(locManager.t(item.label))
                                .font(AppTheme.Typography.micro)
                                .foregroundColor(item.tab == currentPage
                                    ? AppTheme.Colors.textPrimary(colorScheme)
                                    : AppTheme.Colors.textMuted(colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.surface(colorScheme).opacity(0.95))
    }
}
