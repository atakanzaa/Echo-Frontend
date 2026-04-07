//
//  ContentView.swift
//  Echo
//
//  Created by yeniMac on 18.02.2026.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                currentView
                
                // Bottom Navigation Bar (only show for main 4 tabs)
                if selectedTab.isPrimaryNavigationTab {
                    BottomNavBar(selectedTab: $selectedTab)
                }
            }
        }
    }

    @ViewBuilder
    private var currentView: some View {
        switch selectedTab {
        case .home:
            VoiceRecordingView(selectedTab: $selectedTab)
        case .community:
            CommunityView(selectedTab: $selectedTab)
        case .coach:
            NavigationStack {
                CoachSessionsListView(selectedTab: $selectedTab)
            }
        case .profile:
            ProfileViewWrapper(selectedTab: $selectedTab)
        case .journal:
            JournalViewPage(selectedTab: $selectedTab)
        case .calendar:
            CalendarViewPage(selectedTab: $selectedTab)
        case .insights:
            InsightsViewPage(selectedTab: $selectedTab)
        case .aiInsights:
            AIInsightsViewPage(selectedTab: $selectedTab)
        case .achievements:
            AchievementsViewPage(selectedTab: $selectedTab)
        case .timeCapsule:
            TimeCapsuleViewPage(selectedTab: $selectedTab)
        case .premium:
            PremiumViewPage(selectedTab: $selectedTab)
        case .settings:
            SettingsViewPage(selectedTab: $selectedTab)
        case .notifications:
            NotificationsViewPage(selectedTab: $selectedTab)
        case .help:
            HelpSupportViewPage(selectedTab: $selectedTab)
        }
    }
}

struct ProfileViewWrapper: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.149, green: 0.098, blue: 0.196))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Avatar + name
                            VStack(spacing: 16) {
                                ZStack(alignment: .bottomTrailing) {
                                    Circle()
                                        .fill(Color(red: 0.498, green: 0.075, blue: 0.929))
                                        .blur(radius: 4).frame(width: 112, height: 112).opacity(0.4)
                                    Circle()
                                        .strokeBorder(Color(red: 0.098, green: 0.063, blue: 0.133), lineWidth: 4)
                                        .background(Circle().fill(Color(red: 0.141, green: 0.098, blue: 0.188)))
                                        .frame(width: 100, height: 100)
                                        .overlay(Image(systemName: "person.fill")
                                            .font(.system(size: 38))
                                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929)))
                                }
                                .padding(.top, 8)

                                VStack(spacing: 4) {
                                    Text(viewModel.displayName)
                                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                    Text(viewModel.email)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                            }

                            // Stats
                            HStack(spacing: 12) {
                                StatBox(title: "Reflections", value: "\(viewModel.totalEntries)")
                                StatBox(title: "Streak",      value: "\(viewModel.currentStreak)d")
                                StatBox(title: "Mood Avg",   value: viewModel.moodAvgText)
                            }
                            .padding(.horizontal, 16)

                            // Menu items
                            VStack(spacing: 12) {
                                Button(action: { selectedTab = .achievements }) {
                                    ProfileMenuItem(icon: "trophy.fill",           title: "Achievements",  subtitle: "View your progress",  color: Color(red: 0.937, green: 0.722, blue: 0.267))
                                }
                                Button(action: { selectedTab = .notifications }) {
                                    ProfileMenuItem(icon: "bell.fill",             title: "Notifications", subtitle: "Manage alerts",       color: Color(red: 0.498, green: 0.075, blue: 0.929))
                                }
                                Button(action: { selectedTab = .settings }) {
                                    ProfileMenuItem(icon: "gear",                  title: "Settings",      subtitle: "App preferences",     color: Color(red: 0.078, green: 0.357, blue: 0.933))
                                }
                                Button(action: { selectedTab = .help }) {
                                    ProfileMenuItem(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "Need assistance?", color: Color(red: 0.157, green: 0.631, blue: 0.569))
                                }
                            }
                            .padding(.horizontal, 16)

                            // Logout
                            Button(action: { viewModel.logout() }) {
                                if viewModel.isLoggingOut {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.949, green: 0.271, blue: 0.345)))
                                } else {
                                    HStack {
                                        Image(systemName: "arrow.right.square.fill").font(.system(size: 16, weight: .semibold))
                                        Text("Log Out").font(.system(size: 16, weight: .semibold))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .foregroundColor(Color(red: 0.949, green: 0.271, blue: 0.345))
                            .padding(.horizontal, 16).padding(.top, 8)
                            .disabled(viewModel.isLoggingOut)

                            Text(AppConstants.AppInfo.shortVersionLabel)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686).opacity(0.6))
                                .padding(.bottom, 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }

            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab, onLogout: {
                        viewModel.logout()
                    })
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading)).zIndex(1)
            }
        }
        .onAppear { viewModel.loadProfile() }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.078, green: 0.357, blue: 0.933))
            
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0.149, green: 0.098, blue: 0.196))
        .cornerRadius(12)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(red: 0.149, green: 0.098, blue: 0.196))
        .cornerRadius(12)
    }
}

// MARK: - Additional Page Wrappers

struct JournalViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        JournalView(selectedTab: $selectedTab)
    }
}

struct CalendarViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        CalendarView(selectedTab: $selectedTab)
    }
}

struct InsightsViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        InsightsView(selectedTab: $selectedTab)
    }
}

struct AIInsightsViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        AIInsightsView(selectedTab: $selectedTab)
    }
}

struct AchievementsViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        AchievementsView(selectedTab: $selectedTab)
    }
}

struct TimeCapsuleViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        TimeCapsuleView(selectedTab: $selectedTab)
    }
}

struct PremiumViewPage: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        PremiumView(selectedTab: $selectedTab)
    }
}

struct SettingsViewPage: View {
    @Binding var selectedTab: AppTab
    var body: some View { SettingsView(selectedTab: $selectedTab) }
}

struct NotificationsViewPage: View {
    @Binding var selectedTab: AppTab
    var body: some View { NotificationsView(selectedTab: $selectedTab) }
}

struct HelpSupportViewPage: View {
    @Binding var selectedTab: AppTab
    var body: some View { HelpSupportView(selectedTab: $selectedTab) }
}

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    @Published var selectedTab: AppTab
    @Published var isMenuOpen: Bool
    
    init(selectedTab: AppTab, isMenuOpen: Bool) {
        self.selectedTab = selectedTab
        self.isMenuOpen = isMenuOpen
    }
}
