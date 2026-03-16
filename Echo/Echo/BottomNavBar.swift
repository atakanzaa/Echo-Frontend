//
//  BottomNavBar.swift
//  Echo
//
//  Created by yeniMac on 22.02.2026.

import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: String
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(red: 1, green: 1, blue: 1, opacity: 0.05))
            
            HStack(spacing: 0) {
                // Home
                Button(action: { selectedTab = "home" }) {
                    VStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                        
                        Text("Home")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == "home" ? Color(red: 0.078, green: 0.357, blue: 0.933) : Color(red: 0.576, green: 0.639, blue: 0.725))
                }
                
                // Community
                Button(action: { selectedTab = "community" }) {
                    VStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                        
                        Text("Community")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == "community" ? Color(red: 0.078, green: 0.357, blue: 0.933) : Color(red: 0.576, green: 0.639, blue: 0.725))
                }
                
                // Coach
                Button(action: { selectedTab = "coach" }) {
                    VStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                        
                        Text("Coach")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == "coach" ? Color(red: 0.078, green: 0.357, blue: 0.933) : Color(red: 0.576, green: 0.639, blue: 0.725))
                }
                
                // Profile
                Button(action: { selectedTab = "profile" }) {
                    VStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                        
                        Text("Profile")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == "profile" ? Color(red: 0.078, green: 0.357, blue: 0.933) : Color(red: 0.576, green: 0.639, blue: 0.725))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 17)
            .background(Color(red: 0.149, green: 0.098, blue: 0.196))
        }
    }
}

#Preview {
    VStack {
        Spacer()
        BottomNavBar(selectedTab: .constant("home"))
    }
    .background(Color(red: 0.098, green: 0.063, blue: 0.133))
}
