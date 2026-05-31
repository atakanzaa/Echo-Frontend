import SwiftUI

struct ProfileView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isMenuOpen = false
    @State private var showLanguagePicker = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.profile"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: .home)
                    },
                    showMenu: true,
                    onMenu: { withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen.toggle() } }
                )

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Avatar + Name
                            VStack(spacing: AppTheme.Spacing.md) {
                                UserInitialsView(displayName: viewModel.displayName, size: 96)

                                VStack(spacing: 4) {
                                    Text(viewModel.displayName)
                                        .font(AppTheme.Typography.heading2)
                                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    Text(viewModel.email)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                }
                            }
                            .padding(.top, AppTheme.Spacing.sm)

                            // Echo Knows You — tappable row navigates to detail page
                            if let summary = viewModel.profileSummary,
                               summary.userProfile != nil || summary.emotionalPatterns != nil {
                                echoKnowsYouCard(summary: summary)
                            }

                            // Account Settings section
                            SettingsSectionView(title: locManager.t("settings.account")) {
                                SettingsItemView(
                                    icon: "person.circle",
                                    title: locManager.t("profile.edit_profile"),
                                    showArrow: true,
                                    onTap: { selectedTab = .editProfile }
                                )
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                SettingsItemView(
                                    icon: "shield.fill",
                                    iconColor: AppTheme.Colors.moodVeryPositive,
                                    title: locManager.t("settings.privacy_security"),
                                    showArrow: true,
                                    onTap: { selectedTab = .dataPrivacy }
                                )
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                SettingsItemView(
                                    icon: "bell.fill",
                                    title: locManager.t("nav.notifications"),
                                    showArrow: true,
                                    onTap: { selectedTab = .notifications }
                                )
                            }

                            // Experience section
                            SettingsSectionView(title: locManager.t("profile.experience")) {
                                premiumStatusRow
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                SettingsItemView(
                                    icon: "trophy.fill",
                                    iconColor: AppTheme.Colors.gold,
                                    title: locManager.t("nav.achievements"),
                                    showArrow: true,
                                    onTap: { selectedTab = .achievements }
                                )
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                SettingsItemView(
                                    icon: "globe",
                                    iconColor: AppTheme.Colors.textMuted(colorScheme),
                                    title: locManager.t("settings.language"),
                                    showArrow: true,
                                    onTap: { showLanguagePicker = true }
                                )
                            }

                            // More section
                            SettingsSectionView(title: locManager.t("profile.more")) {
                                SettingsItemView(
                                    icon: "questionmark.circle.fill",
                                    iconColor: AppTheme.Colors.moodVeryPositive,
                                    title: locManager.t("profile.help_center"),
                                    showArrow: true,
                                    onTap: { selectedTab = .help }
                                )
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                SettingsItemView(
                                    icon: "gear",
                                    iconColor: AppTheme.Colors.textMuted(colorScheme),
                                    title: locManager.t("nav.settings"),
                                    showArrow: true,
                                    onTap: { selectedTab = .settings }
                                )
                            }

                            // Logout
                            Button(action: { viewModel.logout() }) {
                                HStack(spacing: 10) {
                                    if viewModel.isLoggingOut {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.destructive))
                                    } else {
                                        Image(systemName: "arrow.right.square").font(.system(size: 16))
                                        Text(locManager.t("hamburger.sign_out")).font(AppTheme.Typography.bodyEm)
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.destructive)
                                .frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.sm + 4)
                                .background(AppTheme.Colors.destructive.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                                    .strokeBorder(AppTheme.Colors.destructive.opacity(0.3), lineWidth: 1))
                                .cornerRadius(AppTheme.Spacing.radiusMd)
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .disabled(viewModel.isLoggingOut)

                            AppVersionFooter()
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                }
            }

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab,
                                  onLogout: { viewModel.logout() })
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .onAppear { viewModel.loadProfile() }
        .confirmationDialog(locManager.t("settings.language"), isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button(locManager.t("settings.language_segment_en")) {
                viewModel.updateLanguage("en")
                locManager.currentLanguage = "en"
            }
            Button(locManager.t("settings.language_segment_tr"))  {
                viewModel.updateLanguage("tr")
                locManager.currentLanguage = "tr"
            }
            Button(locManager.t("common.cancel"), role: .cancel) { }
        } message: {
            Text(locManager.t("profile.language_help"))
        }
    }

    // MARK: - Echo Knows You Card

    @ViewBuilder
    private func echoKnowsYouCard(summary: APIProfileSummary) -> some View {
        Button(action: { selectedTab = .aiProfile }) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.accent.opacity(0.12))
                    .cornerRadius(AppTheme.Spacing.radiusMd)

                VStack(alignment: .leading, spacing: 3) {
                    Text(locManager.t("profile.ai_profile"))
                        .font(AppTheme.Typography.bodyEm)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                    if let profile = summary.userProfile, !profile.isEmpty {
                        Text(profile)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated(colorScheme))
            .cornerRadius(AppTheme.Spacing.radiusLg)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Helpers

    private var premiumStatusRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18))
                .echoIconContainer(AppTheme.Colors.gold, size: AppTheme.Layout.compactControlHeight)

            Text(locManager.t("nav.premium"))
                .font(AppTheme.Typography.bodyEm)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

            Spacer()

            Text(locManager.t("common.active"))
                .font(AppTheme.Typography.label).fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(AppTheme.Colors.gold.opacity(0.15))
                .cornerRadius(AppTheme.Spacing.radiusFull)
        }
        .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Profile Stat Cell (kept for potential reuse)

struct ProfileStatCell: View {
    let value: String
    let label: String
    let unit: String?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.heading2)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                if let unit = unit {
                    Text(unit)
                        .font(AppTheme.Typography.micro)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }
            Text(label)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

// Retain SettingItemView for SettingsView (used there)
struct SettingItemView: View {
    let icon: String; let iconColor: Color; let title: String; let subtitle: String
    var badge: String? = nil
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon).font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .cornerRadius(AppTheme.Spacing.radiusSm)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(subtitle).font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Spacer()
            if let badge = badge {
                Text(badge).font(AppTheme.Typography.micro).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(AppTheme.Colors.accent.opacity(0.3)).cornerRadius(4)
            }
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .padding(.horizontal, AppTheme.Spacing.md).padding(.vertical, AppTheme.Spacing.sm + 2)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusMd)
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}
