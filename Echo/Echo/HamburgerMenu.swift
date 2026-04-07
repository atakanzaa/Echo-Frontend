//
//  HamburgerMenu.swift
//  Echo
//
//  Created by yeniMac on 22.02.2026.

import SwiftUI

struct HamburgerMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedTab: AppTab
    var onLogout: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Menu Items
            ScrollView {
                VStack(spacing: 12) {
                    // Main Navigation
                    Text("MAIN")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    MenuItemButton(
                        icon: "house.fill",
                        title: "Home",
                        action: {
                            selectedTab = .home
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "book.fill",
                        title: "Community",
                        action: {
                            selectedTab = .community
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "star.fill",
                        title: "Coach",
                        action: {
                            selectedTab = .coach
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "person.fill",
                        title: "Profile",
                        action: {
                            selectedTab = .profile
                            isMenuOpen = false
                        }
                    )
                    
                    Divider()
                        .background(Color(red: 1, green: 1, blue: 1, opacity: 0.1))
                        .padding(.vertical, 8)
                    
                    // Additional Pages
                    Text("EXPLORE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    MenuItemButton(
                        icon: "book.circle.fill",
                        title: "Journal",
                        action: {
                            selectedTab = .journal
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "calendar",
                        title: "Calendar",
                        action: {
                            selectedTab = .calendar
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "chart.bar.fill",
                        title: "Insights",
                        action: {
                            selectedTab = .insights
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "sparkles",
                        title: "AI Insights",
                        action: {
                            selectedTab = .aiInsights
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "trophy.fill",
                        title: "Achievements",
                        action: {
                            selectedTab = .achievements
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "time",
                        title: "Time Capsule",
                        action: {
                            selectedTab = .timeCapsule
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "crown.fill",
                        title: "Premium",
                        color: Color(red: 0.937, green: 0.722, blue: 0.267),
                        action: {
                            selectedTab = .premium
                            isMenuOpen = false
                        }
                    )
                    
                    Divider()
                        .background(Color(red: 1, green: 1, blue: 1, opacity: 0.1))
                        .padding(.vertical, 8)
                    
                    // Settings & More
                    Text("SETTINGS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    MenuItemButton(
                        icon: "gear",
                        title: "Settings",
                        action: {
                            selectedTab = .settings
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        action: {
                            selectedTab = .help
                            isMenuOpen = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "arrow.backward.circle",
                        title: "Logout",
                        color: Color(red: 0.937, green: 0.267, blue: 0.267),
                        action: {
                            isMenuOpen = false
                            onLogout?()
                        }
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.098, green: 0.063, blue: 0.133))
    }
}

struct MenuItemButton: View {
    let icon: String
    let title: String
    var color: Color = Color(red: 0.078, green: 0.357, blue: 0.933)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(red: 1, green: 1, blue: 1, opacity: 0.05))
            .cornerRadius(8)
        }
    }
}
