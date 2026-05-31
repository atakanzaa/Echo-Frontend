import SwiftUI

struct InsightsView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel     = InsightsViewModel()
    @StateObject private var goalViewModel = GoalViewModel()
    @State private var isMenuOpen = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.insights"),
                    showMenu: true,
                    onMenu: { isMenuOpen.toggle() }
                )

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.summary == nil {
                    ErrorStateView(message: error) {
                        viewModel.loadSummary()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            if let error = viewModel.errorMessage {
                                InlineBannerView(message: error, type: .error) {
                                    viewModel.errorMessage = nil
                                }
                                .padding(.horizontal, AppTheme.Spacing.md)
                            }
                            // Summary Stats
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                Text(locManager.t("insights.this_month"))
                                    .font(AppTheme.Typography.label).fontWeight(.bold)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    .padding(.horizontal, AppTheme.Spacing.md)

                                HStack(spacing: AppTheme.Spacing.sm) {
                                    StatCardView(
                                        title: locManager.t("insights.total_entries"),
                                        value: viewModel.totalEntriesText,
                                        subtitle: locManager.t("insights.days_tracked"),
                                        icon: "book.fill",
                                        color: AppTheme.Colors.accent
                                    )
                                    StatCardView(
                                        title: locManager.t("insights.avg_mood"),
                                        value: viewModel.avgMoodText,
                                        subtitle: locManager.t("insights.out_of_10"),
                                        icon: "heart.fill",
                                        color: AppTheme.Colors.destructive
                                    )
                                }
                                .padding(.horizontal, AppTheme.Spacing.md)
                            }

                            // Emotion Distribution
                            if !viewModel.emotionStats.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Text(locManager.t("insights.emotion_distribution"))
                                        .font(AppTheme.Typography.label).fontWeight(.bold)
                                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                        .padding(.horizontal, AppTheme.Spacing.md)

                                    VStack(spacing: AppTheme.Spacing.sm) {
                                        ForEach(viewModel.emotionStats, id: \.emotion) { stat in
                                            EmotionStatBarView(
                                                emotion: stat.emotion,
                                                count: stat.count,
                                                percentage: stat.percentage
                                            )
                                        }
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
                                    .cornerRadius(AppTheme.Spacing.radiusLg)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                }
                            }

                            // Weekly Trend
                            if !viewModel.weeklyScores.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Text(locManager.t("insights.weekly_trend"))
                                        .font(AppTheme.Typography.label).fontWeight(.bold)
                                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                        .padding(.horizontal, AppTheme.Spacing.md)

                                    VStack(spacing: AppTheme.Spacing.sm) {
                                        APIWeeklyTrendChartView(
                                            scores: viewModel.weeklyScores,
                                            dayLabels: viewModel.weeklyDayLabels
                                        )
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
                                    .cornerRadius(AppTheme.Spacing.radiusLg)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                }
                            }

                            // Narrative Summary
                            if let s = viewModel.summary, !s.narrativeSummary.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text(locManager.t("insights.key_insights"))
                                        .font(AppTheme.Typography.label).fontWeight(.bold)
                                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                        .padding(.horizontal, AppTheme.Spacing.md)

                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                        InsightItemView(
                                            icon: "sparkles",
                                            title: String(format: locManager.t("insights.mood_trend_fmt"), localizedMoodTrend(s.moodTrend)),
                                            description: s.narrativeSummary
                                        )
                                        if !s.dominantTopics.isEmpty {
                                            InsightItemView(
                                                icon: "chart.line.uptrend.xyaxis",
                                                title: locManager.t("insights.top_topics"),
                                                description: s.dominantTopics.prefix(3).joined(separator: ", ")
                                            )
                                        }
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
                                    .cornerRadius(AppTheme.Spacing.radiusLg)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                }
                            }

                            goalsSummaryCard
                        }
                        .padding(.vertical, AppTheme.Spacing.lg)
                    }
                    .refreshable {
                        await viewModel.refresh()
                        await goalViewModel.refresh()
                    }
                }

            }

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.loadSummary()
            goalViewModel.loadGoals()
        }
        .onDisappear {
            viewModel.cancelAll()
            goalViewModel.cancelAll()
        }
    }

    private var goalsSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locManager.t("goals.summary_title"))
                        .font(AppTheme.Typography.label)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    Text(locManager.t("goals.summary_subtitle"))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                }
                Spacer()
                Button(action: { selectedTab = .goals }) {
                    Text(locManager.t("goals.view_action"))
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 10)
                        .background(AppTheme.Gradients.accent)
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                }
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                compactGoalStatCard(
                    title: locManager.t("goals.active_section"),
                    value: "\(goalViewModel.activeGoals.count)",
                    tone: AppTheme.Colors.accent
                )
                compactGoalStatCard(
                    title: locManager.t("goals.completed_section"),
                    value: "\(goalViewModel.completedGoals.count)",
                    tone: AppTheme.Colors.success
                )
            }

            if let preview = goalViewModel.activeGoals.first?.title {
                Text(preview)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func compactGoalStatCard(title: String, value: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(AppTheme.Typography.heading2)
                .foregroundColor(tone)
            Text(title)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusMd)
    }

    private func localizedMoodTrend(_ trend: String) -> String {
        switch trend.lowercased() {
        case "positive", "motivated", "calm":
            return locManager.t("calendar.emotion.motivated")
        case "negative", "stress":
            return locManager.t("calendar.emotion.stress")
        case "neutral":
            return locManager.t("calendar.emotion.neutral")
        default:
            return trend.capitalized
        }
    }
}

// MARK: - API-backed Weekly Trend Chart

struct APIWeeklyTrendChartView: View {
    let scores: [Double]
    var dayLabels: [String] = []
    let maxScore: CGFloat = 10
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                ForEach(0..<scores.count, id: \.self) { index in
                    VStack(spacing: AppTheme.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.Colors.accent,
                                    AppTheme.Colors.accent.opacity(0.5)
                                ]),
                                startPoint: .bottom, endPoint: .top
                            ))
                            .frame(height: max(4, CGFloat(scores[index]) / maxScore * 80))
                        if index < dayLabels.count {
                            Text(dayLabels[index])
                                .font(AppTheme.Typography.micro)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locManager.t("insights.this_week"))
                        .font(AppTheme.Typography.label).fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    let avg = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
                    Text(String(format: locManager.t("insights.avg_format"), avg))
                        .font(AppTheme.Typography.micro)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon).font(AppTheme.Typography.label).foregroundColor(color)
                Text(title).font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Text(value).font(AppTheme.Typography.heading1).foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Text(subtitle).font(AppTheme.Typography.micro).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
        .cornerRadius(AppTheme.Spacing.radiusLg)
    }
}

struct EmotionStatBarView: View {
    let emotion: EmotionalState
    let count: Int
    let percentage: Int
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Circle().fill(emotion.color).frame(width: 8, height: 8)
                Text(locManager.t(emotion.label)).font(AppTheme.Typography.label).fontWeight(.semibold).foregroundColor(.white)
                Spacer()
                Text("\(count) \(locManager.t("profile.days"))").font(AppTheme.Typography.label).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 4).fill(emotion.color.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 6)
            Text("\(percentage)%").font(AppTheme.Typography.micro).foregroundColor(emotion.color)
        }
    }
}

struct InsightItemView: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon).font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.accent).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(AppTheme.Typography.caption).fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(description).font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme)).lineLimit(2)
            }
            Spacer()
        }
    }
}
