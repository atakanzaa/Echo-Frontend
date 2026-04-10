import SwiftUI

struct NotificationListView: View {
    @Binding var selectedTab: String
    @EnvironmentObject private var notificationVM: NotificationViewModel
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    Spacer()
                    Text(locManager.t("notifications.title"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()

                    Button(action: {
                        Task { await notificationVM.markAllRead() }
                    }) {
                        Text(locManager.t("notifications.mark_all_read"))
                            .font(AppTheme.Typography.micro)
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)

                if notificationVM.notifications.isEmpty {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        Text(locManager.t("notifications.empty"))
                            .font(AppTheme.Typography.bodyEm)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        Text(locManager.t("notifications.empty_subtitle"))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(notificationVM.notifications) { item in
                                Button {
                                    Task { await notificationVM.openNotification(item) }
                                    selectedTab = item.tab
                                } label: {
                                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                                        Circle()
                                            .fill(item.isRead ? AppTheme.Colors.textMuted(colorScheme).opacity(0.35) : AppTheme.Colors.accent)
                                            .frame(width: 8, height: 8)
                                            .padding(.top, 6)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(AppTheme.Typography.bodyEm)
                                                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                            Text(item.body)
                                                .font(AppTheme.Typography.caption)
                                                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                                            Text(relativeTime(item.createdAt))
                                                .font(AppTheme.Typography.micro)
                                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.surfaceElevated(colorScheme))
                                    .cornerRadius(AppTheme.Spacing.radiusMd)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                                            .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await notificationVM.loadNotifications()
                await notificationVM.refreshUnreadCount()
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
