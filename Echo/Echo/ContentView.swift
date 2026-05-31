import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isMenuOpen = false
    @StateObject private var userViewModel = ProfileViewModel()
    @StateObject private var tabNavigation = TabNavigationManager()
    @AppStorage("darkMode") private var darkMode = true
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationVM: NotificationViewModel

    private let mainTabs: [AppTab] = [.home, .journal, .community, .coach]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content
            ZStack {
                switch selectedTab {
                case .home:             VoiceRecordingView(selectedTab: $selectedTab)
                case .journal:          JournalView(selectedTab: $selectedTab)
                case .community:        CommunityView(selectedTab: $selectedTab)
                case .coach:            NavigationStack { CoachSessionsListView(selectedTab: $selectedTab) }
                case .goals:            GoalsView(selectedTab: $selectedTab)
                case .calendar:         CalendarView(selectedTab: $selectedTab)
                case .insights:         InsightsView(selectedTab: $selectedTab)
                case .aiInsights:       AIInsightsView(selectedTab: $selectedTab)
                case .achievements:     AchievementsView(selectedTab: $selectedTab)
                case .timeCapsule:      TimeCapsuleView(selectedTab: $selectedTab)
                case .premium:          PremiumView(selectedTab: $selectedTab)
                case .profile:          ProfileView(selectedTab: $selectedTab)
                case .settings:         SettingsView(selectedTab: $selectedTab)
                case .notifications:    NotificationsView(selectedTab: $selectedTab)
                case .notificationList: NotificationListView(selectedTab: $selectedTab)
                case .help:             HelpSupportView(selectedTab: $selectedTab)
                case .aboutApp:         AboutAppView(selectedTab: $selectedTab)
                case .dataPrivacy:      DataAndAIUsageView(selectedTab: $selectedTab)
                case .termsOfUse:       TermsOfUseView(selectedTab: $selectedTab)
                case .privacyPolicy:    PrivacyPolicyView(selectedTab: $selectedTab)
                case .acknowledgements: AcknowledgementsView(selectedTab: $selectedTab)
                case .aiProfile:        EchoKnowsYouView(selectedTab: $selectedTab)
                case .editProfile:      EditProfileView(selectedTab: $selectedTab)
                case .changePassword:   ChangePasswordView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom nav on main tabs
            if mainTabs.contains(selectedTab) {
                BottomNavBar(
                    selectedTab: $selectedTab,
                    unreadNotificationCount: notificationVM.unreadCount,
                    onMenuTap: {
                    withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = true }
                })
                .ignoresSafeArea(edges: .bottom)
            }

            // Hamburger drawer overlay
            if isMenuOpen {
                HamburgerMenuView(
                    isMenuOpen: $isMenuOpen,
                    selectedTab: $selectedTab,
                    userName: userViewModel.displayName,
                    unreadNotificationCount: notificationVM.unreadCount,
                    onLogout: {
                        appState.signOut()
                    }
                )
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(darkMode ? .dark : .light)
        .environmentObject(tabNavigation)
        .onAppear {
            userViewModel.loadProfile()
            Task { await notificationVM.refreshUnreadCount() }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            tabNavigation.recordTransition(from: oldValue, to: newValue)
        }
        .onChange(of: notificationVM.pendingNavigation?.id) { _, _ in
            guard let pending = notificationVM.pendingNavigation else { return }
            selectedTab = pending.tab
            notificationVM.clearPendingNavigation()
        }
    }
}

// MARK: - Reusable Components (shared across views)

struct StatBox: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(value)
                .font(AppTheme.Typography.heading2)
                .foregroundColor(AppTheme.Colors.accent)
            Text(title)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusMd)
    }
}
