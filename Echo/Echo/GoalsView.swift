import SwiftUI

struct GoalsView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = GoalsHubViewModel()
    @State private var isMenuOpen = false
    @EnvironmentObject private var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    header

                    if let success = viewModel.successMessage {
                        InlineBannerView(message: success, type: .info) {
                            viewModel.successMessage = nil
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    if let error = viewModel.errorMessage {
                        InlineBannerView(message: error, type: .error) {
                            viewModel.errorMessage = nil
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    topSummaryCards
                    activeGoalsSection
                    completedGoalsSection
                }
                .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
            }
            .refreshable {
                await viewModel.refresh()
            }

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.load()
        }
        .onDisappear {
            viewModel.cancelAll()
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
            Spacer()
            Text(locManager.t("goals.title"))
                .font(AppTheme.Typography.heading3)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Spacer()
            Button(action: { isMenuOpen.toggle() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.md)
    }

    private var topSummaryCards: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            currentGoalsCard
            completedGoalsCard
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var currentGoalsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(locManager.t("goals.current_title"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(.white)
                    Text(locManager.t("goals.current_subtitle"))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(Color.white.opacity(0.76))
                }
                Spacer()
                Text("\(viewModel.activeGoals.count)")
                    .font(AppTheme.Typography.heading2)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }

            if !viewModel.highlightedActiveTitles.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    ForEach(viewModel.highlightedActiveTitles, id: \.self) { title in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 6, height: 6)
                            Text(title)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(locManager.t("goals.manual_create_title"))
                    .font(AppTheme.Typography.label)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.78))

                TextField(locManager.t("goals.manual_title_placeholder"), text: $viewModel.manualTitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white)
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white.opacity(0.10))
                    .cornerRadius(AppTheme.Spacing.radiusMd)

                TextField(locManager.t("goals.manual_timeframe_placeholder"), text: $viewModel.manualTimeframe)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white)
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(AppTheme.Spacing.radiusMd)

                Button(action: { viewModel.createManualGoal() }) {
                    HStack {
                        if viewModel.isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text(locManager.t("goals.create_action"))
                            .font(AppTheme.Typography.bodyEm)
                    }
                    .foregroundColor(AppTheme.Colors.textPrimary(.light))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(AppTheme.Spacing.radiusMd)
                }
                .disabled(viewModel.isCreating)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Gradients.accent)
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .shadow(
            color: AppTheme.Colors.accent.opacity(0.25),
            radius: 22,
            x: 0,
            y: 10
        )
    }

    private var completedGoalsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(locManager.t("goals.completed_title"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Text(
                        viewModel.latestCompletedTitle.map { _ in locManager.t("goals.completed_subtitle") }
                            ?? locManager.t("goals.completed_empty_subtitle")
                    )
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                Spacer()
                Text("\(viewModel.completedGoals.count)")
                    .font(AppTheme.Typography.heading2)
                    .foregroundColor(AppTheme.Colors.success)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.successSoft(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }

            if let latestCompleted = viewModel.latestCompletedTitle {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.success)
                    Text(latestCompleted)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        .lineLimit(2)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.surface(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
    }

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionTitle(locManager.t("goals.active_section"), count: viewModel.activeGoals.count)

            if viewModel.activeGoals.isEmpty {
                emptyState(
                    title: locManager.t("goals.active_empty_title"),
                    subtitle: locManager.t("goals.active_empty_subtitle")
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.activeGoals) { goal in
                        GoalActionCardView(
                            goal: goal,
                            isMutating: viewModel.isInFlight(goalId: goal.id),
                            onComplete: { viewModel.completeGoal(goal) },
                            onDelete: { viewModel.deleteGoal(goal) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionTitle(locManager.t("goals.completed_section"), count: viewModel.completedGoals.count)

            if viewModel.completedGoals.isEmpty {
                emptyState(
                    title: locManager.t("goals.completed_empty_title"),
                    subtitle: locManager.t("goals.completed_empty_subtitle")
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.completedGoals) { goal in
                        GoalCompletedCardView(
                            goal: goal,
                            isMutating: viewModel.isInFlight(goalId: goal.id),
                            onDelete: { viewModel.deleteGoal(goal) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            Spacer()
            Text("\(count)")
                .font(AppTheme.Typography.label)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.accent)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, 5)
                .background(AppTheme.Colors.accentSoft(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusFull)
        }
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.bodyEm)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Text(subtitle)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
    }
}
