import SwiftUI

struct EmotionalHeatmapCalendarView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = CalendarViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        NavigationView {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Calendar")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-0.5)
                    }
                    Spacer()
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.149, green: 0.098, blue: 0.196))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(height: 56)
                .background(Color.black.opacity(0.3))

                ScrollView {
                    VStack(spacing: 24) {
                        // Month Selector
                        HStack(spacing: 16) {
                            Button(action: { viewModel.prevMonth() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Text(viewModel.displayMonthYear)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { viewModel.nextMonth() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)

                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
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
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }

                Spacer()
                BottomNavigationView(currentPage: "Calendar", selectedTab: $selectedTab)
            }

            // Hamburger Menu Overlay
            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .onAppear { viewModel.loadMonth() }
        }
        .navigationViewStyle(.stack)
    }
}

// Alias for compatibility
typealias CalendarView = EmotionalHeatmapCalendarView

// MARK: - API Calendar Grid

struct APICalendarGridView: View {
    let calendarData: APICalendarMonth
    @Binding var selectedDay: Int?
    let onSelectDay: (Int) -> Void
    let emotionalState: (APICalendarDay) -> EmotionalState

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    let days = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.608, green: 0.639, blue: 0.686))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarData.days, id: \.day) { apiDay in
                    DayButtonView(
                        day: apiDay.day,
                        emotion: emotionalState(apiDay),
                        isSelected: selectedDay == apiDay.day,
                        action: { onSelectDay(apiDay.day) }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - API Selected Day Details

struct APISelectedDayView: View {
    let entry: APIJournalEntry
    @Binding var selectedTab: String

    var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: entry.recordedAt) else { return entry.entryDate }
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: tarih, sure, mood badge + score
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    if !entry.formattedDuration.isEmpty {
                        Text("\(entry.formattedDuration) Audio")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    }
                }
                Spacer()
                if let analysis = entry.analysis {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(entry.emotionalState.color)
                                .frame(width: 8, height: 8)
                            Text((analysis.moodLabel ?? "neutral").uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(entry.emotionalState.color)
                        }
                        if let score = analysis.moodScore {
                            Text(String(format: "%.1f/10", score * 10))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(entry.emotionalState.color.opacity(0.15))
                    .cornerRadius(12)
                }
            }

            // Key Emotions chip'leri
            if let emotions = entry.analysis?.keyEmotions, !emotions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(emotions.prefix(4), id: \.self) { emotion in
                            Text(emotion)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.25))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            if let analysis = entry.analysis {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.8))
                        Text("AI SUMMARY")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.8))
                    }
                    Text(analysis.summary ?? "")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                        .lineSpacing(2)
                }
                .padding(17)
                .background(Color.black.opacity(0.2))
                .cornerRadius(24)

                if let question = analysis.reflectiveQuestion, !question.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REFLECTION QUESTION")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502))
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color(red: 0.498, green: 0.075, blue: 0.929))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(question)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                        }
                    }
                }
            }

            // Detay butonu
            NavigationLink(destination: JournalDetailView(entry: entry, selectedTab: $selectedTab)) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                    Text("Detayi Gor")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.12))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(25)
        .background(Color(red: 0.165, green: 0.114, blue: 0.212))
        .cornerRadius(24)
    }
}

// MARK: - Unchanged supporting structs

// 4 score-range categories + empty (no entry)
// 0.00-0.25 → stress | 0.25-0.50 → neutral | 0.50-0.75 → calm | 0.75-1.00 → motivated
enum EmotionalState {
    case stress, neutral, calm, motivated, empty

    var color: Color {
        switch self {
        case .stress:    return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        case .neutral:   return Color(red: 0.612, green: 0.639, blue: 0.686) // #9CA3AF
        case .calm:      return Color(red: 0.235, green: 0.808, blue: 0.996) // #3CCEFF
        case .motivated: return Color(red: 0.133, green: 0.769, blue: 0.368) // #22C45E
        case .empty:     return Color.clear
        }
    }

    var label: String {
        switch self {
        case .stress:    return "Stress"
        case .neutral:   return "Neutral"
        case .calm:      return "Calm"
        case .motivated: return "Motivated"
        case .empty:     return ""
        }
    }
}

struct DayButtonView: View {
    let day: Int
    let emotion: EmotionalState
    let isSelected: Bool
    let action: () -> Void

    private var hasEntry: Bool { emotion != .empty }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 15, weight: hasEntry ? .semibold : .regular))
                    .foregroundColor(hasEntry ? .white : Color(red: 0.420, green: 0.360, blue: 0.460))

                // Mood dot — only visible when entry exists
                Circle()
                    .fill(emotion.color)
                    .frame(width: 6, height: 6)
                    .opacity(hasEntry ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

struct LegendView: View {
    private let legends: [(EmotionalState, String)] = [
        (.stress, "Stress"), (.neutral, "Neutral"), (.calm, "Calm"), (.motivated, "Motivated")
    ]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(legends, id: \.1) { state, label in
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.color)
                        .frame(width: 8, height: 8)
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct BottomNavigationView: View {
    let currentPage: String
    @Binding var selectedTab: String

    private static let items: [(icon: String, label: String, tab: String)] = [
        ("book.fill",      "Journal",  "journal"),
        ("calendar",       "Calendar", "calendar"),
        ("chart.bar.fill", "Insights", "insights"),
        ("gear",           "Settings", "settings")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.05))
            HStack(spacing: 0) {
                ForEach(Self.items, id: \.tab) { item in
                    Button(action: { selectedTab = item.tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(item.label == currentPage ? .white : Color(red: 0.612, green: 0.639, blue: 0.686))
                            Text(item.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(item.label == currentPage ? .white : Color(red: 0.612, green: 0.639, blue: 0.686))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Color(red: 0.102, green: 0.067, blue: 0.133).opacity(0.95))
    }
}
