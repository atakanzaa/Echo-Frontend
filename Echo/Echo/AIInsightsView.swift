import SwiftUI

struct AIInsightsView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = AIInsightsViewModel()
    @State private var isMenuOpen = false
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.ai_insights"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "home")
                    },
                    showMenu: true,
                    onMenu: { isMenuOpen.toggle() }
                )

                // Period Selector
                Menu {
                    ForEach(viewModel.periodOptions) { opt in
                        Button {
                            if opt.unlocked {
                                viewModel.selectPeriod(opt.days)
                            }
                        } label: {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Text(locManager.t(opt.label))
                                if !opt.unlocked {
                                    Image(systemName: "lock.fill")
                                    if let progress = opt.progress {
                                        Text(progress)
                                    }
                                }
                            }
                        }
                        .disabled(!opt.unlocked)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(locManager.t(viewModel.selectedPeriodLabel))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                }
                .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                .padding(.vertical, AppTheme.Spacing.md)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.insights == nil {
                    ErrorStateView(message: error) {
                        viewModel.loadEligibility()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.insights != nil && !viewModel.hasSufficientData {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.Colors.accent)
                        Text(locManager.t("ai.insufficient_data"))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            if let error = viewModel.errorMessage {
                                InlineBannerView(message: error, type: .error) {
                                    viewModel.errorMessage = nil
                                }
                                .padding(.horizontal, AppTheme.Spacing.md)
                            }
                            // Mood Score
                            VStack(spacing: AppTheme.Spacing.lg) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(AppTheme.Gradients.accent, lineWidth: 12)
                                        .frame(height: 192)
                                    VStack(spacing: 4) {
                                        Text(viewModel.moodPercentText)
                                            .font(AppTheme.Typography.display)
                                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                        Text("/10")
                                            .font(AppTheme.Typography.label)
                                            .fontWeight(.medium)
                                            .tracking(0.6)
                                            .foregroundColor(AppTheme.Colors.accent)
                                        if let insights = viewModel.insights, !insights.moodTrend.isEmpty {
                                            Text(insights.moodTrend.capitalized)
                                                .font(AppTheme.Typography.micro)
                                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                        }
                                    }
                                }
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text(locManager.t("ai.overall_mood"))
                                        .font(AppTheme.Typography.heading3)
                                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    if let insights = viewModel.insights {
                                        Text(String(format: locManager.t("ai.mood_baseline_fmt"), insights.moodTrend.lowercased()))
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.lg)
                            .background(AppTheme.Colors.surface(colorScheme))
                            .cornerRadius(AppTheme.Spacing.radiusXl)
                            .padding(.horizontal, AppTheme.Spacing.md)

                            // Emotional Trends
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                HStack {
                                    Text(locManager.t("ai.emotional_trends"))
                                        .font(AppTheme.Typography.heading3)
                                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    Spacer()
                                    if viewModel.hasPreviousPeriodData {
                                        HStack(spacing: 4) {
                                            if !viewModel.isTrendFlat {
                                                Image(systemName: viewModel.isTrendPositive ? "arrow.up.right" : "arrow.down.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                            }
                                            Text(viewModel.trendText)
                                                .font(AppTheme.Typography.caption).fontWeight(.semibold)
                                        }
                                        .foregroundColor(viewModel.isTrendPositive ? AppTheme.Colors.success : AppTheme.Colors.destructive)
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.lg)
                            .background(AppTheme.Colors.surface(colorScheme))
                            .cornerRadius(AppTheme.Spacing.radiusXl)
                            .padding(.horizontal, AppTheme.Spacing.md)

                            // Repeated Themes
                            if let insights = viewModel.insights, !insights.themes.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Text(locManager.t("ai.repeated_themes"))
                                        .font(AppTheme.Typography.heading3)
                                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: AppTheme.Spacing.sm) {
                                        ForEach(insights.themes, id: \.tag) { theme in
                                            ThemeTag("#\(theme.tag)")
                                        }
                                    }
                                }
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surface(colorScheme))
                                .cornerRadius(AppTheme.Spacing.radiusXl)
                                .padding(.horizontal, AppTheme.Spacing.md)
                            }

                            // AI Suggestions
                            if let insights = viewModel.insights, !insights.suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Text(locManager.t("ai.suggestions"))
                                        .font(AppTheme.Typography.label).fontWeight(.bold)
                                        .tracking(0.5)
                                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    ForEach(insights.suggestions, id: \.title) { suggestion in
                                        SuggestionCardView(
                                            icon: suggestion.icon ?? "lightbulb.fill",
                                            title: suggestion.title,
                                            description: suggestion.body
                                        )
                                    }
                                }
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surface(colorScheme))
                                .cornerRadius(AppTheme.Spacing.radiusXl)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.bottom, AppTheme.Spacing.xxl)
                            }
                        }
                        .padding(.top, AppTheme.Spacing.md)
                    }
                    .refreshable {
                        await viewModel.refreshAll()
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
        .onAppear { viewModel.loadEligibility() }
        .onDisappear { viewModel.cancelAll() }
    }
}


struct ThemeTag: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(AppTheme.Typography.label)
            .foregroundColor(AppTheme.Colors.accentSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.accentSoft(colorScheme))
            .cornerRadius(AppTheme.Spacing.radiusMd)
    }
}

struct SuggestionCardView: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accentSecondary)
                .frame(width: 40, height: 40)
                .background(AppTheme.Colors.accentSoft(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusSm)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.caption).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Spacer()
        }
    }
}
