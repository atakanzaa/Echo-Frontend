import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @AppStorage("darkMode") private var darkMode = true
    @State private var notificationsEnabled = true
    @State private var dailyReminder = true
    @State private var privateMode = false
    @State private var soundEnabled = true
    @State private var showDeleteAlert = false
    @State private var isMenuOpen = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(locManager.t("settings.title"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()

                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                }
                .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                .padding(.top, AppTheme.Layout.headerTop)
                .padding(.bottom, AppTheme.Layout.headerBottom)

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Account Section
                        SettingsSectionView(title: locManager.t("settings.account")) {
                            SettingsItemView(
                                icon: "person.crop.circle",
                                title: locManager.t("settings.profile"),
                                subtitle: locManager.t("settings.profile_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "edit-profile" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "key",
                                title: locManager.t("settings.change_password"),
                                subtitle: locManager.t("settings.change_password_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "change-password" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "lock",
                                title: locManager.t("settings.privacy"),
                                subtitle: locManager.t("settings.privacy_sub"),
                                showArrow: true
                            )
                        }

                        // Notifications Section
                        SettingsSectionView(title: locManager.t("settings.notifications")) {
                            SettingsToggleView(
                                icon: "bell.circle.fill",
                                title: locManager.t("settings.push"),
                                subtitle: locManager.t("settings.push_sub"),
                                isOn: $notificationsEnabled
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsToggleView(
                                icon: "clock.circle.fill",
                                title: locManager.t("settings.daily"),
                                subtitle: locManager.t("settings.daily_sub"),
                                isOn: $dailyReminder
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsToggleView(
                                icon: "speaker.wave.2.circle.fill",
                                title: locManager.t("settings.sound"),
                                subtitle: locManager.t("settings.sound_sub"),
                                isOn: $soundEnabled
                            )
                        }

                        // Appearance Section
                        SettingsSectionView(title: locManager.t("settings.appearance")) {
                            SettingsToggleView(
                                icon: "moon.circle.fill",
                                title: locManager.t("settings.dark_mode"),
                                subtitle: locManager.t("settings.dark_mode_sub"),
                                isOn: $darkMode
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "textformat.size",
                                title: locManager.t("settings.text_size"),
                                subtitle: locManager.t("settings.text_size_sub"),
                                showArrow: true
                            )
                        }

                        SettingsSectionView(title: locManager.t("settings.language")) {
                            Picker(locManager.t("settings.language"), selection: $locManager.currentLanguage) {
                                Text(locManager.t("settings.language_segment_tr")).tag("tr")
                                Text(locManager.t("settings.language_segment_en")).tag("en")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Privacy & Security Section
                        SettingsSectionView(title: locManager.t("settings.privacy_security")) {
                            SettingsToggleView(
                                icon: "eye.slash.circle.fill",
                                title: locManager.t("settings.private_mode"),
                                subtitle: locManager.t("settings.private_mode_sub"),
                                isOn: $privateMode
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "hand.raised.circle.fill",
                                title: locManager.t("settings.data_privacy"),
                                subtitle: locManager.t("settings.data_privacy_sub"),
                                showArrow: true
                            )
                        }

                        // Support Section
                        SettingsSectionView(title: locManager.t("settings.support")) {
                            SettingsItemView(
                                icon: "questionmark.circle.fill",
                                title: locManager.t("settings.help_faq"),
                                subtitle: locManager.t("settings.help_faq_sub"),
                                showArrow: true
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "envelope.circle.fill",
                                title: locManager.t("settings.contact_support"),
                                subtitle: locManager.t("settings.contact_support_sub"),
                                showArrow: true
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "star.circle.fill",
                                title: locManager.t("settings.rate_app"),
                                subtitle: locManager.t("settings.rate_app_sub"),
                                showArrow: true
                            )
                        }

                        // About Section
                        SettingsSectionView(title: locManager.t("settings.about")) {
                            SettingsStaticItemView(
                                icon: "info.circle.fill",
                                title: locManager.t("settings.app_version"),
                                subtitle: "1.0.0"
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "doc.circle.fill",
                                title: locManager.t("settings.terms"),
                                subtitle: locManager.t("settings.terms_sub"),
                                showArrow: true
                            )
                        }

                        // Danger Zone
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Button(action: { showDeleteAlert = true }) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.Colors.destructive)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(locManager.t("settings.delete_all_data"))
                                            .font(AppTheme.Typography.caption).fontWeight(.semibold)
                                            .foregroundColor(AppTheme.Colors.destructive)
                                        Text(locManager.t("settings.delete_all_data_sub"))
                                            .font(AppTheme.Typography.label)
                                            .foregroundColor(AppTheme.Colors.destructive.opacity(0.7))
                                    }

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.destructive.opacity(0.1))
                                .cornerRadius(AppTheme.Spacing.radiusMd)
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                                    .strokeBorder(AppTheme.Colors.destructive.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    .padding(.vertical, AppTheme.Spacing.lg)
                }

            }
            .alert(locManager.t("settings.delete_alert_title"), isPresented: $showDeleteAlert) {
                Button(locManager.t("common.cancel"), role: .cancel) { }
                Button(locManager.t("common.delete"), role: .destructive) { }
            } message: {
                Text(locManager.t("settings.delete_alert_body"))
            }

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}

struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.md)

            VStack(spacing: 0) {
                content
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
            .cornerRadius(AppTheme.Spacing.radiusLg)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
}

struct SettingsItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let showArrow: Bool
    let onTap: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme

    init(icon: String, title: String, subtitle: String, showArrow: Bool, onTap: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showArrow = showArrow
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            SettingsRowLayout(icon: icon, title: title, subtitle: subtitle) {
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsStaticItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SettingsRowLayout(icon: icon, title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct SettingsToggleView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SettingsRowLayout(icon: icon, title: title, subtitle: subtitle) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.Colors.accent)
        }
    }
}

private struct SettingsRowLayout<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing
    @Environment(\.colorScheme) var colorScheme

    private let iconWidth: CGFloat = 24
    private let rowSpacing: CGFloat = AppTheme.Spacing.md

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: rowSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(width: iconWidth, alignment: .center)

                Text(title)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                Spacer()
                trailing
            }

            Text(subtitle)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .padding(.leading, iconWidth + rowSpacing)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}
