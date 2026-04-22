import SwiftUI

enum AppHeaderMenuPlacement {
    case leading
    case trailing
}

struct AppScreenHeader<Trailing: View>: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)?
    var showMenu: Bool = false
    var onMenu: (() -> Void)?
    var menuPlacement: AppHeaderMenuPlacement = .trailing
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        showBack: Bool = false,
        onBack: (() -> Void)? = nil,
        showMenu: Bool = false,
        onMenu: (() -> Void)? = nil,
        menuPlacement: AppHeaderMenuPlacement = .trailing,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.showBack = showBack
        self.onBack = onBack
        self.showMenu = showMenu
        self.onMenu = onMenu
        self.menuPlacement = menuPlacement
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            leadingControl

            Spacer(minLength: AppTheme.Spacing.sm)

            Text(title)
                .font(AppTheme.Typography.heading3)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: AppTheme.Spacing.sm)

            trailingControl
        }
        .padding(.horizontal, AppTheme.Layout.screenHorizontal)
        .padding(.top, AppTheme.Layout.headerTop)
        .padding(.bottom, AppTheme.Layout.headerBottom)
        .background(AppTheme.Colors.background(colorScheme).opacity(0.001))
    }

    @ViewBuilder
    private var leadingControl: some View {
        if showBack {
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
            .frame(width: AppTheme.Layout.iconButtonSize, height: AppTheme.Layout.iconButtonSize)
            .contentShape(Rectangle())
        } else if showMenu && menuPlacement == .leading {
            Button(action: { onMenu?() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
            .frame(width: AppTheme.Layout.iconButtonSize, height: AppTheme.Layout.iconButtonSize)
            .background(AppTheme.Colors.surface(colorScheme))
            .clipShape(Circle())
        } else {
            Color.clear.frame(width: AppTheme.Layout.iconButtonSize, height: AppTheme.Layout.iconButtonSize)
        }
    }

    @ViewBuilder
    private var trailingControl: some View {
        let content = trailing()
        if showMenu && menuPlacement == .trailing {
            Button(action: { onMenu?() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
            .frame(width: AppTheme.Layout.iconButtonSize, height: AppTheme.Layout.iconButtonSize)
            .background(AppTheme.Colors.surface(colorScheme))
            .clipShape(Circle())
        } else {
            content
                .frame(minWidth: AppTheme.Layout.iconButtonSize, minHeight: AppTheme.Layout.iconButtonSize, alignment: .trailing)
        }
    }
}

extension AppScreenHeader where Trailing == EmptyView {
    init(
        title: String,
        showBack: Bool = false,
        onBack: (() -> Void)? = nil,
        showMenu: Bool = false,
        onMenu: (() -> Void)? = nil,
        menuPlacement: AppHeaderMenuPlacement = .trailing
    ) {
        self.init(title: title, showBack: showBack, onBack: onBack, showMenu: showMenu, onMenu: onMenu, menuPlacement: menuPlacement) {
            EmptyView()
        }
    }
}

struct SectionCard<Content: View>: View {
    var padding: CGFloat = AppTheme.Layout.cardPadding
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(padding: CGFloat = AppTheme.Layout.cardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(padding)
        .echoCard(colorScheme)
    }
}

struct AppSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.label)
                .fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.md)

            SectionCard {
                content
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
}

struct AppSettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: Trailing

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .echoIconContainer(iconColor, size: AppTheme.Layout.compactControlHeight)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: AppTheme.Spacing.sm)
            trailing
        }
        .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

extension AppSettingsRow where Trailing == EmptyView {
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil) {
        self.init(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct LoadingStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
    }
}

struct KeyboardAwareFormScroll<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .padding(.bottom, AppTheme.Layout.sheetBottomInset)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
