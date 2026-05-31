import SwiftUI

struct HamburgerMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedTab: AppTab
    var userName: String = ""
    var unreadNotificationCount: Int? = nil
    var onLogout: (() -> Void)? = nil
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var notificationVM: NotificationViewModel
    @Environment(\.colorScheme) var colorScheme

    private let accentLight = Color(red: 0.769, green: 0.604, blue: 1.0) // #c49aff

    private var effectiveUnreadCount: Int {
        unreadNotificationCount ?? notificationVM.unreadCount
    }
    
    private var userInitials: String {
        let normalized = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = normalized.isEmpty ? locManager.t("common.user") : normalized
        let components = baseName.split(separator: " ").map(String.init)
        if components.count >= 2 {
            return (String(components[0].prefix(1)) + String(components[1].prefix(1))).uppercased()
        }
        return String(baseName.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = false } }

            // Drawer
            VStack(spacing: 0) {
                // Header — Echo wordmark + close
                HStack {
                    Text("Echo")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.Gradients.accent)
                    Spacer()
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = false } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentLight)
                            .frame(width: 32, height: 32)
                            .background(Color(red: 0.165, green: 0.102, blue: 0.212))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.md)

                // Profile Card
                HStack(spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        LinearGradient(
                            colors: [AppTheme.Colors.accent, AppTheme.Colors.accentSecondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)

                        Text(userInitials)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(locManager.t("nav.profile"))
                            .font(AppTheme.Typography.caption).fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(locManager.t("hamburger.profile_sub"))
                            .font(AppTheme.Typography.label)
                            .foregroundColor(accentLight.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(AppTheme.Spacing.sm)
                .background(Color(red: 0.165, green: 0.114, blue: 0.212))
                .cornerRadius(AppTheme.Spacing.radiusMd)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.md)
                .onTapGesture { navigate(.profile) }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 2) {
                        // Main nav
                        drawerItem(icon: "house.fill",        label: locManager.t("nav.home"),         tab: .home)
                        drawerItem(icon: "book.fill",         label: locManager.t("nav.journal"),      tab: .journal)
                        drawerItem(icon: "person.3.fill",     label: locManager.t("nav.community"),    tab: .community)
                        drawerItem(icon: "sparkles",          label: locManager.t("hamburger.ai_coach"), tab: .coach)

                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.vertical, AppTheme.Spacing.sm)

                        drawerItem(icon: "calendar",          label: locManager.t("nav.calendar"),     tab: .calendar)
                        drawerItem(icon: "target",            label: locManager.t("nav.goals"),        tab: .goals)
                        drawerItem(icon: "chart.bar.fill",    label: locManager.t("nav.insights"),     tab: .insights)
                        drawerItem(icon: "brain.head.profile",label: locManager.t("nav.ai_insights"),  tab: .aiInsights)
                        drawerItem(icon: "trophy.fill",       label: locManager.t("nav.achievements"), tab: .achievements)
                        drawerItem(icon: "clock.fill",        label: locManager.t("nav.time_capsule"), tab: .timeCapsule)

                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.vertical, AppTheme.Spacing.sm)

                        // Premium card
                        Button(action: { navigate(.premium) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(locManager.t("hamburger.echo_premium"))
                                        .font(AppTheme.Typography.caption).fontWeight(.bold)
                                        .foregroundColor(AppTheme.Colors.gold)
                                    Text(locManager.t("hamburger.echo_premium_sub"))
                                        .font(AppTheme.Typography.label)
                                        .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.Colors.gold)
                            }
                            .padding(AppTheme.Spacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.400, green: 0.300, blue: 0.100).opacity(0.4),
                                        Color(red: 0.200, green: 0.150, blue: 0.050).opacity(0.4)
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                                    .strokeBorder(AppTheme.Colors.gold.opacity(0.25), lineWidth: 1)
                            )
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                        }

                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.vertical, AppTheme.Spacing.sm)

                        drawerItem(icon: "gear", label: locManager.t("nav.settings"), tab: .settings)
                        drawerItem(
                            icon: "bell.fill",
                            label: locManager.t("notifications.title"),
                            tab: .notificationList,
                            badgeCount: effectiveUnreadCount
                        )
                        drawerItem(icon: "questionmark.circle", label: locManager.t("nav.help_support"), tab: .help)

                        // Logout
                        Button(action: { isMenuOpen = false; onLogout?() }) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.Colors.destructive)
                                    .frame(width: 28, height: 28)
                                Text(locManager.t("hamburger.sign_out"))
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.destructive)
                                Spacer()
                            }
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }

                Spacer(minLength: 0)

                // Version
                Text(AppConstants.AppInfo.footerVersionLabel)
                    .font(AppTheme.Typography.micro)
                    .foregroundColor(Color.white.opacity(0.2))
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .frame(width: 280)
            .background(Color(red: 0.098, green: 0.055, blue: 0.137))
            .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func navigate(_ tab: AppTab) {
        selectedTab = tab
        withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = false }
    }

    @ViewBuilder
    private func drawerItem(icon: String, label: String, tab: AppTab, badgeCount: Int = 0) -> some View {
        let isActive = selectedTab == tab
        Button(action: { navigate(tab) }) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? AppTheme.Colors.accent : Color(red: 0.678, green: 0.573, blue: 0.792))
                    .frame(width: 28, height: 28)
                Text(label)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(isActive ? Color(red: 0.769, green: 0.604, blue: 1.0) : .white)
                if badgeCount > 0 {
                    NotificationBadge(count: badgeCount)
                }
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .background(isActive ? Color(red: 0.153, green: 0.102, blue: 0.200) : Color.clear)
            .cornerRadius(AppTheme.Spacing.radiusSm)
        }
    }
}
