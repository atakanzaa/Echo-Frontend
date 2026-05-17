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
}
