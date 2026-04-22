import SwiftUI

struct NotificationsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.notifications"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                    }
                )

                ScrollView {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: locManager.t("notifications.preferences_unavailable_title"),
                        subtitle: locManager.t("notifications.preferences_unavailable_subtitle")
                    )
                    .padding(.top, AppTheme.Spacing.xl)
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
        .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight)
        .padding(.vertical, 4)
    }
}
