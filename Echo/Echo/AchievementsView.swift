import SwiftUI

struct AchievementsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @StateObject private var viewModel = AchievementsViewModel()
    @StateObject private var communityViewModel = CommunityViewModel()
    @State private var isMenuOpen = false
    @State private var selectedBadge: APIBadge?
    @State private var showCreatePost = false
    @State private var prefillContent: String?
    @State private var prefillEmoji: String?
    @State private var lockedBadgeProgress: [String: Double] = [:]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.achievements"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                    },
                    showMenu: true,
                    onMenu: { isMenuOpen.toggle() }
                )

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.badges.isEmpty {
                    ErrorStateView(message: error) {
                        viewModel.load()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Streak Circle
                            VStack(spacing: AppTheme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(AppTheme.Gradients.accent, lineWidth: 8)
                                        .frame(height: 180)

                                    VStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppTheme.Colors.accentSecondary)
                                        Text("\(viewModel.currentStreak) \(locManager.t("profile.days"))")
                                            .font(AppTheme.Typography.heading1)
                                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                        Text(locManager.t("achievements.current_streak"))
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    }
                                }

                                VStack(spacing: AppTheme.Spacing.sm) {
                                    if !viewModel.level.isEmpty {
                                        Text(viewModel.level)
                                            .font(AppTheme.Typography.label)
                                            .foregroundColor(AppTheme.Colors.success)
                                            .padding(.horizontal, AppTheme.Spacing.sm)
                                            .padding(.vertical, 4)
                                            .background(AppTheme.Colors.success.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    Text(viewModel.streakMessage)
                                        .font(AppTheme.Typography.heading3)
                                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    if !viewModel.levelMessage.isEmpty {
                                        Text(viewModel.levelMessage)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                            .multilineTextAlignment(.center).lineLimit(3)
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.lg)

                            // Stats Row
                            HStack(spacing: AppTheme.Spacing.sm) {
                                AchievementStatCardView(icon: "mic.fill",         value: "\(viewModel.totalEntries)", label: locManager.t("achievements.entries"))
                                AchievementStatCardView(icon: "text.bubble.fill", value: viewModel.totalWordsText,    label: locManager.t("achievements.words"))
                                AchievementStatCardView(icon: "sparkles",         value: viewModel.insightScoreText,  label: locManager.t("achievements.insight"))
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            // Badge Collection
                            if !viewModel.badges.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    HStack {
                                        Text(locManager.t("achievements.collection"))
                                            .font(AppTheme.Typography.heading3)
                                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                        Spacer()
                                        Text(String(format: NSLocalizedString("%d earned", comment: ""), viewModel.badges.filter(\.isEarned).count))
                                            .font(AppTheme.Typography.caption).fontWeight(.semibold)
                                            .foregroundColor(AppTheme.Colors.accentSecondary)
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.md)

                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
                                            GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
                                        ],
                                        spacing: AppTheme.Spacing.sm
                                    ) {
                                        ForEach(viewModel.badges) { badge in
                                            BadgeCard(
                                                name: badge.title,
                                                emoji: badge.emoji,
                                                earned: badge.isEarned,
                                                progress: badge.isEarned ? nil : lockedBadgeProgress[badge.key]
                                            )
                                            .onTapGesture { selectedBadge = badge }
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                }
                                .padding(.top, AppTheme.Spacing.sm)
                                .padding(.bottom, AppTheme.Spacing.xxl)
                            }
                        }
                        .padding(.top, AppTheme.Spacing.md)
                    }
                    .refreshable {
                        await viewModel.refresh()
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
        .onAppear { viewModel.load() }
        .onDisappear { viewModel.cancelAll() }
        .onChange(of: viewModel.badges) { _, badges in
            preloadLockedBadgeProgress(for: badges)
        }
        .sheet(item: $selectedBadge) { badge in
            AchievementDetailView(badge: badge) { shareText, emoji in
                prefillContent = shareText
                prefillEmoji = emoji
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showCreatePost = true
                }
            }
        }
        .sheet(isPresented: $showCreatePost, onDismiss: {
            prefillContent = nil
            prefillEmoji = nil
        }) {
            CreatePostView(
                viewModel: communityViewModel,
                prefillContent: prefillContent,
                prefillEmoji: prefillEmoji
            )
        }
    }

    private func preloadLockedBadgeProgress(for badges: [APIBadge]) {
        Task {
            for badge in badges where !badge.isEarned && lockedBadgeProgress[badge.key] == nil {
                do {
                    let detail: APIAchievementDetail = try await APIClient.shared.requestWithAutoRefresh(
                        .getAchievementDetail(badgeKey: badge.key)
                    )
                    await MainActor.run {
                        lockedBadgeProgress[badge.key] = detail.progress
                    }
                } catch {
                    continue
                }
            }
        }
    }
}

struct AchievementStatCardView: View {
    let icon: String; let value: String; let label: String
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon).font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.accentSecondary)
            Text(value).font(AppTheme.Typography.heading3).foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Text(label).font(AppTheme.Typography.label).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusMd)
    }
}

struct BadgeCard: View {
    let name: String
    let emoji: String
    let earned: Bool
    let progress: Double?
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(emoji).font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(AppTheme.Colors.surfaceElevated(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
                .opacity(earned ? 1.0 : 0.4)
            Text(name).font(AppTheme.Typography.caption).fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                .lineLimit(2).multilineTextAlignment(.center).opacity(earned ? 1.0 : 0.6)
            if earned {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.success)
                    Text(locManager.t("achievements.earned"))
                        .font(AppTheme.Typography.micro)
                        .foregroundColor(AppTheme.Colors.success)
                }
            } else {
                Text(locManager.t("achievements.locked")).font(AppTheme.Typography.micro)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                ProgressView(value: min(max(progress ?? 0, 0), 1))
                    .tint(AppTheme.Colors.accent)
                    .scaleEffect(x: 1, y: 0.7, anchor: .center)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 126, maxHeight: 126)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.background(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusMd)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
            .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
    }
}
