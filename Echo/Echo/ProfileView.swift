import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Color.clear.frame(width: 24, height: 24)
                    Spacer()
                    Text("Profile").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            VStack(spacing: 16) {
                                ZStack(alignment: .bottomTrailing) {
                                    Circle()
                                        .fill(Color(red: 0.498, green: 0.075, blue: 0.929))
                                        .blur(radius: 4).frame(width: 112, height: 112).opacity(0.4)
                                    Circle()
                                        .strokeBorder(Color(red: 0.098, green: 0.063, blue: 0.133), lineWidth: 4)
                                        .background(Circle().fill(Color(red: 0.141, green: 0.098, blue: 0.188)))
                                        .frame(width: 112, height: 112)
                                        .overlay(Image(systemName: "person.fill").font(.system(size: 40))
                                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929)))
                                    Circle()
                                        .fill(Color(red: 0.498, green: 0.075, blue: 0.929))
                                        .strokeBorder(Color(red: 0.098, green: 0.063, blue: 0.133), lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                        .overlay(Image(systemName: "pencil").font(.system(size: 10, weight: .semibold)).foregroundColor(.white))
                                }

                                VStack(spacing: 4) {
                                    Text(viewModel.displayName)
                                        .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                                    Text(viewModel.email)
                                        .font(.system(size: 14)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                            }

                            // Stats Row
                            HStack(spacing: 32) {
                                VStack(spacing: 4) {
                                    Text("\(viewModel.totalEntries)")
                                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                    Text("ENTRIES").font(.system(size: 12, weight: .medium)).tracking(0.6)
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                                Divider().frame(height: 32).opacity(0.1)
                                VStack(spacing: 4) {
                                    Text("\(viewModel.currentStreak)")
                                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                    Text("STREAK").font(.system(size: 12, weight: .medium)).tracking(0.6)
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                                Divider().frame(height: 32).opacity(0.1)
                                VStack(spacing: 4) {
                                    Text(viewModel.moodAvgText)
                                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                    Text("MOOD AVG").font(.system(size: 12, weight: .medium)).tracking(0.6)
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)

                            // Settings
                            VStack(spacing: 12) {
                                Text("PERSONAL").font(.system(size: 12, weight: .medium)).tracking(0.5)
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24).padding(.top, 8)
                                SettingItemView(icon: "person.fill", iconColor: Color(red: 0.498, green: 0.075, blue: 0.929),
                                               title: "Account Settings", subtitle: "Email, password, profile details")
                                SettingItemView(icon: "shield.fill", iconColor: Color(red: 0.157, green: 0.631, blue: 0.569),
                                               title: "Privacy & Security", subtitle: "Manage data access & visibility", badge: "SAFE")
                            }

                            VStack(spacing: 12) {
                                Text("DATA & PLAN").font(.system(size: 12, weight: .medium)).tracking(0.5)
                                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24).padding(.top, 8)
                                SettingItemView(icon: "arrow.down.circle.fill", iconColor: Color(red: 1.0, green: 0.576, blue: 0.0),
                                               title: "Export Data", subtitle: "Download journal as PDF")
                                SettingItemView(icon: "heart.fill", iconColor: Color(red: 0.949, green: 0.216, blue: 0.522),
                                               title: "Subscription Status", subtitle: "Manage renewal and billing", badge: "PRO")
                            }

                            // Log Out
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
                            .padding(.horizontal, 24).padding(.top, 16)
                            .disabled(viewModel.isLoggingOut)

                            Text("Version \(AppConstants.AppInfo.shortVersion)")
                                .font(.system(size: 12)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686).opacity(0.6))
                                .padding(.top, 24).padding(.bottom, 40)
                        }
                        .padding(.top, 16)
                    }
                }
            }
        }
        .onAppear { viewModel.loadProfile() }
    }
}

struct SettingItemView: View {
    let icon: String; let iconColor: Color; let title: String; let subtitle: String
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor).frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 13)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            Spacer()
            if let badge = badge {
                Text(badge).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.3)).cornerRadius(4)
            }
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color(red: 0.141, green: 0.098, blue: 0.188)).cornerRadius(12)
        .padding(.horizontal, 24)
    }
}
