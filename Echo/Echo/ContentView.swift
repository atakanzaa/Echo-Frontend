import SwiftUI

struct ContentView: View {
    @State private var selectedTab: String = "home"
    @State private var isMenuOpen = false
    @StateObject private var userViewModel = ProfileViewModel()
    @StateObject private var tabNavigation = TabNavigationManager()
    @AppStorage(AppConstants.Storage.darkMode) private var darkMode = true
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationVM: NotificationViewModel

    private let mainTabs = ["home", "journal", "community", "coach"]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content
            ZStack {
                if selectedTab == "home"          { VoiceRecordingView(selectedTab: $selectedTab) }
                else if selectedTab == "journal"   { JournalView(selectedTab: $selectedTab) }
                else if selectedTab == "community" { CommunityView(selectedTab: $selectedTab) }
                else if selectedTab == "coach"     { NavigationStack { CoachSessionsListView(selectedTab: $selectedTab) } }
                else if selectedTab == "goals"     { GoalsView(selectedTab: $selectedTab) }
                else if selectedTab == "calendar"  { CalendarView(selectedTab: $selectedTab) }
                else if selectedTab == "insights"  { InsightsView(selectedTab: $selectedTab) }
                else if selectedTab == "aiinsights"    { AIInsightsView(selectedTab: $selectedTab) }
                else if selectedTab == "achievements"   { AchievementsView(selectedTab: $selectedTab) }
                else if selectedTab == "timecapsule"    { TimeCapsuleView(selectedTab: $selectedTab) }
                else if selectedTab == "premium"        { PremiumView(selectedTab: $selectedTab) }
                else if selectedTab == "profile"        { ProfileView(selectedTab: $selectedTab) }
                else if selectedTab == "settings"       { SettingsView(selectedTab: $selectedTab) }
                else if selectedTab == "notifications"  { NotificationsView(selectedTab: $selectedTab) }
                else if selectedTab == "notification_list" { NotificationListView(selectedTab: $selectedTab) }
                else if selectedTab == "help"           { HelpSupportView(selectedTab: $selectedTab) }
                else if selectedTab == "about-app"      { AboutAppView(selectedTab: $selectedTab) }
                else if selectedTab == "data-privacy"   { DataAndAIUsageView(selectedTab: $selectedTab) }
                else if selectedTab == "terms-of-use"   { TermsOfUseView(selectedTab: $selectedTab) }
                else if selectedTab == "privacy-policy" { PrivacyPolicyView(selectedTab: $selectedTab) }
                else if selectedTab == "acknowledgements" { AcknowledgementsView(selectedTab: $selectedTab) }
                else if selectedTab == "ai-profile"    { EchoKnowsYouView(selectedTab: $selectedTab) }
                else if selectedTab == "edit-profile"   { EditProfileView(selectedTab: $selectedTab) }
                else if selectedTab == "change-password" { ChangePasswordView(selectedTab: $selectedTab) }
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
