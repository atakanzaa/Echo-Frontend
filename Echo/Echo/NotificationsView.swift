import SwiftUI

struct NotificationsView: View {
    @Binding var selectedTab: AppTab

    @AppStorage("notif_push")    private var pushEnabled    = true
    @AppStorage("notif_daily")   private var dailyReminder  = true
    @AppStorage("notif_sound")   private var soundEnabled   = true
    @AppStorage("notif_weekly")  private var weeklySummary  = false
    @AppStorage("notif_streak")  private var streakReminder = true

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { selectedTab = .profile }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Notifications")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        // General
                        NotifSection(title: "GENERAL") {
                            NotifToggleRow(
                                icon: "bell.fill",
                                iconColor: Color(red: 0.498, green: 0.075, blue: 0.929),
                                title: "Push Notifications",
                                subtitle: "Receive all app notifications",
                                isOn: $pushEnabled
                            )
                        }

                        // Reminders
                        NotifSection(title: "REMINDERS") {
                            NotifToggleRow(
                                icon: "clock.fill",
                                iconColor: Color(red: 1.0, green: 0.576, blue: 0.0),
                                title: "Daily Reminder",
                                subtitle: "Remind me to record my journal",
                                isOn: $dailyReminder
                            )
                            Divider().background(Color.white.opacity(0.06))
                            NotifToggleRow(
                                icon: "flame.fill",
                                iconColor: Color(red: 0.937, green: 0.267, blue: 0.267),
                                title: "Streak Reminder",
                                subtitle: "Don't break your streak",
                                isOn: $streakReminder
                            )
                            Divider().background(Color.white.opacity(0.06))
                            NotifToggleRow(
                                icon: "chart.bar.fill",
                                iconColor: Color(red: 0.157, green: 0.631, blue: 0.569),
                                title: "Weekly Summary",
                                subtitle: "Get your weekly mood report",
                                isOn: $weeklySummary
                            )
                        }

                        // Sound
                        NotifSection(title: "AUDIO") {
                            NotifToggleRow(
                                icon: "speaker.wave.2.fill",
                                iconColor: Color(red: 0.078, green: 0.357, blue: 0.933),
                                title: "Sound Effects",
                                subtitle: "Audio feedback on actions",
                                isOn: $soundEnabled
                            )
                        }

                        // Info note
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                            Text("To manage system-level permissions, go to iPhone Settings → Echo.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        }
                        .padding(.horizontal, 16).padding(.top, 4)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }
}

private struct NotifSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold)).tracking(0.6)
                .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502))
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Color(red: 0.141, green: 0.098, blue: 0.188))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}

private struct NotifToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 13)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(red: 0.498, green: 0.075, blue: 0.929))
        }
        .padding(.vertical, 4)
    }
}
