import SwiftUI

struct InsightsView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel     = InsightsViewModel()
    @StateObject private var goalViewModel = GoalViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Insights")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(-0.5)
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

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Summary Stats
                            VStack(alignment: .leading, spacing: 16) {
                                Text("This Month")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    .padding(.horizontal, 16)

                                HStack(spacing: 12) {
                                    StatCardView(
                                        title: "Total Entries",
                                        value: viewModel.totalEntriesText,
                                        subtitle: "days tracked",
                                        icon: "book.fill",
                                        color: Color(red: 0.498, green: 0.075, blue: 0.929)
                                    )
                                    StatCardView(
                                        title: "Avg. Mood",
                                        value: viewModel.avgMoodText,
                                        subtitle: "out of 10",
                                        icon: "heart.fill",
                                        color: Color(red: 0.937, green: 0.267, blue: 0.267)
                                    )
                                }
                                .padding(.horizontal, 16)
                            }

                            // Emotion Distribution
                            if !viewModel.emotionStats.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Emotion Distribution")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                        .padding(.horizontal, 16)

                                    VStack(spacing: 12) {
                                        ForEach(viewModel.emotionStats, id: \.label) { stat in
                                            EmotionStatBarView(
                                                emotion: stat.emotion,
                                                count: stat.percentage / 4,
                                                percentage: stat.percentage
                                            )
                                        }
                                    }
                                    .padding(16)
                                    .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                }
                            }

                            // Weekly Trend — sadece gerçek veri varsa göster
                            if !viewModel.weeklyScores.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Weekly Trend")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                        .padding(.horizontal, 16)

                                    VStack(spacing: 12) {
                                        APIWeeklyTrendChartView(
                                            scores: viewModel.weeklyScores,
                                            dayLabels: viewModel.weeklyDayLabels
                                        )
                                    }
                                    .padding(16)
                                    .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                }
                            }

                            // Narrative Summary
                            if let s = viewModel.summary, !s.narrativeSummary.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Key Insights")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                        .padding(.horizontal, 16)

                                    VStack(alignment: .leading, spacing: 12) {
                                        InsightItemView(
                                            icon: "sparkles",
                                            title: s.moodTrend.capitalized + " Trend",
                                            description: s.narrativeSummary
                                        )
                                        if !s.dominantTopics.isEmpty {
                                            InsightItemView(
                                                icon: "chart.line.uptrend.xyaxis",
                                                title: "Top Topics",
                                                description: s.dominantTopics.prefix(3).joined(separator: ", ")
                                            )
                                        }
                                    }
                                    .padding(16)
                                    .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                }
                            }

                            // Active Goals
                            if !goalViewModel.activeGoals.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Active Goals")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                        Spacer()
                                        Text("\(goalViewModel.activeGoals.count)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.15))
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 16)

                                    VStack(spacing: 8) {
                                        ForEach(goalViewModel.activeGoals) { goal in
                                            GoalRowView(
                                                goal: goal,
                                                onComplete: { goalViewModel.completeGoal(goal) },
                                                onDismiss:  { goalViewModel.dismissGoal(goal) }
                                            )
                                        }
                                    }
                                    .padding(16)
                                    .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }

                Spacer()
                BottomNavigationView(currentPage: "Insights", selectedTab: $selectedTab)
            }

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
        .onAppear {
            viewModel.loadSummary()
            goalViewModel.loadActiveGoals()
        }
    }
}

// MARK: — API-backed Weekly Trend Chart

struct APIWeeklyTrendChartView: View {
    let scores: [Double]
    var dayLabels: [String] = []
    let maxScore: CGFloat = 10

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<scores.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.498, green: 0.075, blue: 0.929),
                                    Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.5)
                                ]),
                                startPoint: .bottom, endPoint: .top
                            ))
                            .frame(height: max(4, CGFloat(scores[index]) / maxScore * 80))
                        if index < dayLabels.count {
                            Text(dayLabels[index])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    let avg = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
                    Text(String(format: "Avg: %.1f/10", avg))
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
                Spacer()
            }
        }
    }
}

// MARK: — Unchanged supporting views

struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
            Text(subtitle).font(.system(size: 11)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
        .cornerRadius(16)
    }
}

struct EmotionStatBarView: View {
    let emotion: EmotionalState
    let count: Int
    let percentage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(emotion.color).frame(width: 8, height: 8)
                Text(emotion.label).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Spacer()
                Text("\(count) days").font(.system(size: 12)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 4).fill(emotion.color.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)
            Text("\(percentage)%").font(.system(size: 11)).foregroundColor(emotion.color)
        }
    }
}

struct InsightItemView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 16))
                .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929)).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text(description).font(.system(size: 12)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686)).lineLimit(2)
            }
            Spacer()
        }
    }
}

// MARK: — Goal Row

struct GoalRowView: View {
    let goal:       APIGoal
    let onComplete: () -> Void
    let onDismiss:  () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                if let tf = goal.timeframe, !tf.isEmpty {
                    Text(tf)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.133, green: 0.769, blue: 0.368))
                }
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
