//
//  BottomNavBar.swift
//  Echo
//
//  Created by yeniMac on 22.02.2026.

import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: AppTab
    @Environment(\.colorScheme) private var colorScheme

    private static let items: [(tab: AppTab, icon: String, label: String)] = [
        (.home, "house.fill", "Home"),
        (.community, "book.fill", "Community"),
        (.coach, "star.fill", "Coach"),
        (.profile, "person.fill", "Profile")
    ]

    private var selectedColor: Color {
        colorScheme == .dark
            ? Color(red: 0.078, green: 0.357, blue: 0.933)
            : Color(red: 0.055, green: 0.290, blue: 0.780)
    }

    private var unselectedColor: Color {
        colorScheme == .dark
            ? Color(red: 0.576, green: 0.639, blue: 0.725)
            : Color(red: 0.431, green: 0.486, blue: 0.565)
    }

    private var barBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.149, green: 0.098, blue: 0.196)
            : Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.08))
            
            HStack(spacing: 0) {
                ForEach(Self.items, id: \.tab) { item in
                    Button(action: { selectedTab = item.tab }) {
                        VStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20))

                            Text(item.label)
                                .font(.system(size: 12, weight: .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(
                            selectedTab == item.tab
                                ? selectedColor
                                : unselectedColor
                        )
                    }
                    .accessibilityLabel(item.label)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 17)
            .background(barBackground)
        }
    }
}
