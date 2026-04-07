import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.openURL) private var openURL
    @State private var notificationsEnabled = true
    @State private var dailyReminder = true
    @State private var darkMode = true
    @State private var privateMode = false
    @State private var soundEnabled = true
    @State private var showDeleteAlert = false
    @State private var isMenuOpen = false
    @State private var infoMessage: String?
    
    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Settings")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-0.5)
                    }
                    
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
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(height: 56)
                .background(Color.black.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section
                        SettingsSectionView(title: "Account") {
                            SettingsItemView(
                                icon: "person.crop.circle",
                                title: "Profile",
                                subtitle: "View and edit profile",
                                showArrow: true
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsItemView(
                                icon: "lock",
                                title: "Privacy",
                                subtitle: "Manage privacy settings",
                                showArrow: true
                            )
                        }
                        
                        // Notifications Section
                        SettingsSectionView(title: "Notifications") {
                            SettingsToggleView(
                                icon: "bell.circle.fill",
                                title: "Push Notifications",
                                subtitle: "Receive notifications",
                                isOn: $notificationsEnabled
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsToggleView(
                                icon: "clock.circle.fill",
                                title: "Daily Reminder",
                                subtitle: "9:00 AM daily",
                                isOn: $dailyReminder
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsToggleView(
                                icon: "speaker.wave.2.circle.fill",
                                title: "Sound Effects",
                                subtitle: "Audio feedback",
                                isOn: $soundEnabled
                            )
                        }
                        
                        // Appearance Section
                        SettingsSectionView(title: "Appearance") {
                            SettingsToggleView(
                                icon: "moon.circle.fill",
                                title: "Dark Mode",
                                subtitle: "Always enabled",
                                isOn: $darkMode
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsItemView(
                                icon: "textformat.size",
                                title: "Text Size",
                                subtitle: "Medium",
                                showArrow: true
                            )
                        }
                        
                        // Privacy & Security Section
                        SettingsSectionView(title: "Privacy & Security") {
                            SettingsToggleView(
                                icon: "eye.slash.circle.fill",
                                title: "Private Mode",
                                subtitle: "Hide sensitive data",
                                isOn: $privateMode
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsItemView(
                                icon: "hand.raised.circle.fill",
                                title: "Data & Privacy",
                                subtitle: "Learn about our practices",
                                showArrow: true,
                                action: { openURL(AppConstants.Links.privacy) }
                            )
                        }
                        
                        // Support Section
                        SettingsSectionView(title: "Support") {
                            SettingsItemView(
                                icon: "questionmark.circle.fill",
                                title: "Help & FAQ",
                                subtitle: "Get answers and tips",
                                showArrow: true,
                                action: { selectedTab = .help }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsItemView(
                                icon: "envelope.circle.fill",
                                title: "Contact Support",
                                subtitle: "Get in touch with us",
                                showArrow: true,
                                action: {
                                    if let url = URL(string: "mailto:\(AppConstants.Links.supportEmail)") {
                                        openURL(url)
                                    }
                                }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsItemView(
                                icon: "star.circle.fill",
                                title: "Rate Our App",
                                subtitle: "Share your feedback",
                                showArrow: true,
                                action: {
                                    infoMessage = "App Store ratings will be enabled when Echo launches publicly."
                                }
                            )
                        }
                        
                        // About Section
                        SettingsSectionView(title: "About") {
                            SettingsStaticItemView(
                                icon: "info.circle.fill",
                                title: "App Version",
                                subtitle: AppConstants.AppInfo.shortVersion
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.05))
                            
                            SettingsItemView(
                                icon: "doc.circle.fill",
                                title: "Terms of Service",
                                subtitle: "Read our terms",
                                showArrow: true,
                                action: { openURL(AppConstants.Links.terms) }
                            )
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { showDeleteAlert = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Delete All Data")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                                        
                                        Text("Permanently delete all entries")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.7))
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.1))
                                .border(Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.3))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 24)
                }
                
                Spacer()
                
                BottomNavigationView(currentTab: .settings, selectedTab: $selectedTab)
            }
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { }
            } message: {
                Text("This action cannot be undone. All journal entries and data will be permanently deleted.")
            }
            .alert("Coming Soon", isPresented: .init(
                get: { infoMessage != nil },
                set: { if !$0 { infoMessage = nil } }
            )) {
                Button("OK") { infoMessage = nil }
            } message: {
                Text(infoMessage ?? "")
            }
            
            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }
}

struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502))
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
            .border(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}

struct SettingsItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let showArrow: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
                
                Spacer()
                
                if showArrow && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(action != nil)
    }
}

struct SettingsStaticItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            
            Spacer()
        }
    }
}

struct SettingsToggleView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Color(red: 0.498, green: 0.075, blue: 0.929))
        }
    }
}
