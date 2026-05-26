import SwiftUI

struct ProfileView: View {
    @Binding var selectedTab: String
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
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "home")
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
                            profileSection(locManager.t("settings.account")) {
                                profileRow(icon: "person.circle", label: locManager.t("profile.edit_profile"), color: AppTheme.Colors.accent) {
                                    selectedTab = "edit-profile"
                                }
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                profileRow(icon: "shield.fill", label: locManager.t("settings.privacy_security"), color: AppTheme.Colors.moodVeryPositive) {
                                    selectedTab = "data-privacy"
                                }
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                profileRow(icon: "bell.fill", label: locManager.t("nav.notifications"), color: AppTheme.Colors.accent) { selectedTab = "notifications" }
                            }

                            // Experience section
                            profileSection(locManager.t("profile.experience")) {
                                HStack {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.Colors.gold)
                                            .frame(width: 32, height: 32)
                                            .background(AppTheme.Colors.gold.opacity(0.12))
                                            .cornerRadius(AppTheme.Spacing.radiusSm)
                                        Text(locManager.t("nav.premium"))
                                            .font(AppTheme.Typography.body)
                                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    }
                                    Spacer()
                                    Text(locManager.t("common.active"))
                                        .font(AppTheme.Typography.label).fontWeight(.semibold)
                                        .foregroundColor(AppTheme.Colors.gold)
                                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 4)
                                        .background(AppTheme.Colors.gold.opacity(0.15))
                                        .cornerRadius(AppTheme.Spacing.radiusFull)
                                }
                                .padding(.vertical, 4)
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                profileRow(icon: "trophy.fill", label: locManager.t("nav.achievements"), color: AppTheme.Colors.gold) { selectedTab = "achievements" }
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                profileRow(icon: "globe", label: locManager.t("settings.language"), color: AppTheme.Colors.textMuted(colorScheme)) {
                                    showLanguagePicker = true
                                }
                            }

                            // More section
                            profileSection(locManager.t("profile.more")) {
                                profileRow(icon: "questionmark.circle.fill", label: locManager.t("profile.help_center"), color: AppTheme.Colors.moodVeryPositive) { selectedTab = "help" }
                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                profileRow(icon: "gear", label: locManager.t("nav.settings"), color: AppTheme.Colors.textMuted(colorScheme)) { selectedTab = "settings" }
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
                locManager.currentLanguage = "en"
            }
            Button(locManager.t("settings.language_segment_tr")) {
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
        Button(action: { selectedTab = "ai-profile" }) {
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

    @ViewBuilder
    private func profileSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.md)

            VStack(spacing: 0) {
                content()
            }
            .padding(AppTheme.Spacing.md)
            .echoCard(colorScheme)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    @ViewBuilder
    private func profileRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .cornerRadius(AppTheme.Spacing.radiusSm)
                Text(label)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight)
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
