import SwiftUI

// MARK: - Rounded Corner Shape

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Bottom Nav Bar

struct BottomNavBar: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    var unreadNotificationCount: Int = 0
    var onMenuTap: (() -> Void)? = nil

    var body: some View {
        let inactiveColor = AppTheme.Colors.textMuted(.dark)
        let tabs: [(id: String, icon: String, labelKey: String)] = [
            ("home",      "house.fill",    "nav.home"),
            ("journal",   "book.fill",     "nav.journal"),
            ("community", "person.3.fill", "nav.community"),
            ("coach",     "sparkles",      "nav.coach"),
        ]

        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                Button(action: { selectedTab = tab.id }) {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                        Text(locManager.t(tab.labelKey))
                            .font(AppTheme.Typography.micro)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == tab.id
                        ? AppTheme.Colors.accent
                        : inactiveColor)
                }
                .accessibilityLabel(locManager.t(tab.labelKey))
            }

            Button(action: { onMenuTap?() }) {
                VStack(spacing: 5) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 22))
                        NotificationBadge(count: unreadNotificationCount)
                            .offset(x: 10, y: -8)
                    }
                    Text(locManager.t("nav.menu"))
                        .font(AppTheme.Typography.micro)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(inactiveColor)
            }
            .accessibilityLabel(locManager.t("nav.menu"))
            .accessibilityValue(unreadNotificationCount > 0 ? "\(unreadNotificationCount)" : "")
        }
        .padding(.horizontal, AppTheme.Layout.screenHorizontal)
        .padding(.top, AppTheme.Layout.headerBottom)
        .padding(.bottom, AppTheme.Spacing.xl)
        .background(
            AppTheme.Colors.background(.dark).opacity(0.95)
        )
        .clipShape(RoundedCornerShape(radius: 32, corners: [.topLeft, .topRight]))
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: -4)
    }
}
