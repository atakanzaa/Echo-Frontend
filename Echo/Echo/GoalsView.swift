import SwiftUI

struct GoalsView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = GoalsHubViewModel()
    @State private var isMenuOpen = false
    @State private var isComposerSheet = false
    @State private var isArchiveExpanded = false

    @EnvironmentObject private var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    AppScreenHeader(
                        title: locManager.t("goals.title"),
                        showBack: true,
                        onBack: {
                            selectedTab = tabNavigation.goBack(from: selectedTab, fallback: .profile)
                        },
                        showMenu: true,
                        onMenu: { isMenuOpen.toggle() }
                    )

                    if let error = viewModel.errorMessage {
                        InlineBannerView(message: error, type: .error) {
                            viewModel.errorMessage = nil
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    statsStrip
                    aiSuggestionsSection
                    activeList
                    archiveGroup
                }
                .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
            }
            .refreshable {
                await viewModel.refresh()
            }

            createFab
                .padding(.trailing, AppTheme.Layout.screenHorizontal)
                .padding(.bottom, AppTheme.Spacing.xl)

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $isComposerSheet) {
            ManualGoalSheet(viewModel: viewModel, isPresented: $isComposerSheet)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear { viewModel.load() }
        .onDisappear { viewModel.cancelAll() }
    }

    // MARK: — FAB

    private var createFab: some View {
        Button { isComposerSheet = true } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text(locManager.t("goals.create_action"))
                    .font(AppTheme.Typography.bodyEm)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppTheme.Gradients.accent)
            .cornerRadius(AppTheme.Spacing.radiusFull)
            .shadow(color: AppTheme.Colors.accent.opacity(0.35), radius: 18, y: 8)
        }
    }

    // MARK: — Stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statTile(
                value: "\(viewModel.activeGoals.count)",
                label: locManager.t("goals.stat_active"),
                tone: AppTheme.Colors.accent
            )
            divider
            statTile(
                value: "\(viewModel.completedThisWeek)",
                label: locManager.t("goals.stat_week"),
                tone: AppTheme.Colors.textPrimary(colorScheme)
            )
            divider
            statTile(
                value: "\(viewModel.completedGoals.count)",
                label: locManager.t("goals.stat_total"),
                tone: AppTheme.Colors.success
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.Colors.borderSubtle(colorScheme))
            .frame(width: 1, height: 32)
    }

    private func statTile(value: String, label: String, tone: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.Typography.heading2)
                .foregroundColor(tone)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — AI suggestions

    @ViewBuilder
    private var aiSuggestionsSection: some View {
        if !viewModel.aiSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.Colors.accent)
                    Text(locManager.t("goals.ai_suggestions_section"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()
                }
                Text(locManager.t("goals.ai_suggestions_subtitle"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.aiSuggestions) { suggestion in
                        GoalSuggestionCardView(
                            suggestion: suggestion,
                            isLoading: viewModel.isSuggestionInFlight(id: suggestion.id),
                            onPrimary: { viewModel.acceptSuggestion(suggestion) },
                            onSecondary: { viewModel.rejectSuggestion(suggestion) }
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: — Active list

    private var activeList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text(locManager.t("goals.active_section"))
                    .font(AppTheme.Typography.heading3)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Spacer()
            }

            if viewModel.activeGoals.isEmpty {
                MomentumEmptyState(
                    title: locManager.t("goals.active_empty_title"),
                    subtitle: locManager.t("goals.active_empty_subtitle"),
                    actionTitle: locManager.t("goals.create_action"),
                    onAction: { isComposerSheet = true }
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

    // MARK: — Archive (collapsed completed)

    @ViewBuilder
    private var archiveGroup: some View {
        if !viewModel.completedGoals.isEmpty {
            VStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        isArchiveExpanded.toggle()
                    }
                } label: {
                    archiveHeader
                }
                .buttonStyle(.plain)

                if isArchiveExpanded {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(viewModel.completedGoals) { goal in
                            GoalCompletedCardView(
                                goal: goal,
                                isMutating: viewModel.isInFlight(goalId: goal.id),
                                onDelete: { viewModel.deleteGoal(goal) }
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    private var archiveHeader: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle().fill(AppTheme.Colors.successSoft(colorScheme))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.Colors.success)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(locManager.t("goals.completed_section"))
                    .font(AppTheme.Typography.bodyEm)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(locManager.t("goals.completed_archive_hint"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Spacer()
            Text("\(viewModel.completedGoals.count)")
                .font(AppTheme.Typography.label)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.Colors.successSoft(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusFull)
            Image(systemName: isArchiveExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
    }
}

// MARK: — Manual create bottom sheet

private struct ManualGoalSheet: View {
    @ObservedObject var viewModel: GoalsHubViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text(locManager.t("goals.manual_create_title"))
                    .font(AppTheme.Typography.heading3)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(locManager.t("goals.manual_create_subtitle"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                fieldLabel(locManager.t("goals.manual_title_label"))
                TextField(locManager.t("goals.manual_title_placeholder"), text: $viewModel.manualTitle)
                    .font(AppTheme.Typography.body)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.surfaceElevated(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusMd)

                fieldLabel(locManager.t("goals.manual_timeframe_label"))
                TextField(locManager.t("goals.manual_timeframe_placeholder"), text: $viewModel.manualTimeframe)
                    .font(AppTheme.Typography.body)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.surfaceElevated(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }

            Button {
                viewModel.createManualGoal()
                isPresented = false
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isCreating {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    }
                    Text(locManager.t("goals.create_action"))
                        .font(AppTheme.Typography.bodyEm)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.Gradients.accent)
                .cornerRadius(AppTheme.Spacing.radiusMd)
            }
            .disabled(viewModel.isCreating || viewModel.manualTitle.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.background(colorScheme))
    }

    private func fieldLabel(_ s: String) -> some View {
        Text(s)
            .font(AppTheme.Typography.label)
            .fontWeight(.bold)
            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
    }
}

// MARK: — Empty state with CTA

private struct MomentumEmptyState: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let onAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentSoft(colorScheme))
                    .frame(width: 64, height: 64)
                Image(systemName: "target")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
            }
            VStack(spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.bodyEm)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    .multilineTextAlignment(.center)
            }
            Button(action: onAction) {
                Text(actionTitle)
                    .font(AppTheme.Typography.label)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(AppTheme.Gradients.accent)
                    .cornerRadius(AppTheme.Spacing.radiusFull)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
    }
}
