import SwiftUI

struct NotificationsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager

    @AppStorage("notif_push")    private var pushEnabled    = true
    @AppStorage("notif_daily")   private var dailyReminder  = true
    @AppStorage("notif_sound")   private var soundEnabled   = true
    @AppStorage("notif_weekly")  private var weeklySummary  = false
    @AppStorage("notif_streak")  private var streakReminder = true
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    Spacer()
                    Text(locManager.t("nav.notifications"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // General
                        notifSection(title: locManager.t("notifications.general")) {
                            NotifToggleRow(
                                icon: "bell.fill", iconColor: AppTheme.Colors.accent,
                                title: locManager.t("notifications.push"),
                                subtitle: locManager.t("notifications.push_sub"),
                                isOn: $pushEnabled
                            )
                        }

                        // Reminders
                        notifSection(title: locManager.t("notifications.reminders")) {
                            NotifToggleRow(
                                icon: "clock.fill", iconColor: Color(red: 1.0, green: 0.576, blue: 0.0),
                                title: locManager.t("notifications.daily"),
                                subtitle: locManager.t("notifications.daily_sub"),
                                isOn: $dailyReminder
                            )
                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                            NotifToggleRow(
                                icon: "flame.fill", iconColor: AppTheme.Colors.destructive,
                                title: locManager.t("notifications.streak"),
                                subtitle: locManager.t("notifications.streak_sub"),
                                isOn: $streakReminder
                            )
                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                            NotifToggleRow(
                                icon: "chart.bar.fill", iconColor: AppTheme.Colors.success,
                                title: locManager.t("notifications.weekly"),
                                subtitle: locManager.t("notifications.weekly_sub"),
                                isOn: $weeklySummary
                            )
                        }

                        // Audio
                        notifSection(title: locManager.t("notifications.audio")) {
                            NotifToggleRow(
                                icon: "speaker.wave.2.fill", iconColor: AppTheme.Colors.accent,
                                title: locManager.t("notifications.sound"),
                                subtitle: locManager.t("notifications.sound_sub"),
                                isOn: $soundEnabled
                            )
                        }

                        // Info note
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "info.circle")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            Text(locManager.t("notifications.system_note"))
                                .font(AppTheme.Typography.label)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                    .padding(.vertical, AppTheme.Spacing.md)
                }
            }
        }
    }

    @ViewBuilder
    private func notifSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.md)

            VStack(spacing: 0) {
                content()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated(colorScheme))
            .cornerRadius(AppTheme.Spacing.radiusLg)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
}

private struct NotifToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(AppTheme.Spacing.radiusSm)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(AppTheme.Colors.accent)
        }
        .padding(.vertical, 4)
    }
}
