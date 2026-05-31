import SwiftUI
import UIKit

struct SettingsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @AppStorage(AppConstants.Storage.darkMode) private var darkMode = true
    @AppStorage(AppConstants.Storage.privateMode) private var privateMode = false
    @State private var isMenuOpen = false
    @State private var activeWebDestination: WebDestination?
    @State private var showMailFallback = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("settings.title"),
                    showMenu: true,
                    onMenu: { isMenuOpen.toggle() }
                )

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
                                showArrow: true,
                                onTap: { selectedTab = "data-privacy" }
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
                                showArrow: true,
                                onTap: {
                                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                        ExternalNavigator.openURL(settingsURL)
                                    }
                                }
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
                                showArrow: true,
                                onTap: { selectedTab = "data-privacy" }
                            )
                        }

                        // Support Section
                        SettingsSectionView(title: locManager.t("settings.support")) {
                            SettingsItemView(
                                icon: "questionmark.circle.fill",
                                title: locManager.t("settings.help_faq"),
                                subtitle: locManager.t("settings.help_faq_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "help" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "envelope.circle.fill",
                                title: locManager.t("settings.contact_support"),
                                subtitle: locManager.t("settings.contact_support_sub"),
                                showArrow: true,
                                onTap: {
                                    if !ExternalNavigator.openSupportAction(.contactSupport, localization: locManager) {
                                        showMailFallback = true
                                    }
                                }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "exclamationmark.bubble.circle.fill",
                                title: locManager.t("settings.report_problem"),
                                subtitle: locManager.t("settings.report_problem_sub"),
                                showArrow: true,
                                onTap: {
                                    if !ExternalNavigator.openSupportAction(.reportProblem, localization: locManager) {
                                        showMailFallback = true
                                    }
                                }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "bubble.left.and.text.bubble.right.circle.fill",
                                title: locManager.t("settings.send_feedback"),
                                subtitle: locManager.t("settings.send_feedback_sub"),
                                showArrow: true,
                                onTap: {
                                    if !ExternalNavigator.openSupportAction(.sendFeedback, localization: locManager) {
                                        showMailFallback = true
                                    }
                                }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "star.circle.fill",
                                title: locManager.t("settings.rate_app"),
                                subtitle: locManager.t("settings.rate_app_sub"),
                                showArrow: true,
                                onTap: { ExternalNavigator.requestAppReview() }
                            )
                        }

                        // About Section
                        SettingsSectionView(title: locManager.t("settings.about")) {
                            SettingsItemView(
                                icon: "sparkles.rectangle.stack.fill",
                                title: locManager.t("settings.about_echo"),
                                subtitle: locManager.t("settings.about_echo_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "about-app" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsStaticItemView(
                                icon: "info.circle.fill",
                                title: locManager.t("settings.app_version"),
                                subtitle: AppConstants.AppInfo.fullVersionLabel
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "hand.raised.circle.fill",
                                title: locManager.t("settings.privacy_policy"),
                                subtitle: locManager.t("settings.privacy_policy_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "privacy-policy" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "doc.circle.fill",
                                title: locManager.t("settings.terms_of_use"),
                                subtitle: locManager.t("settings.terms_of_use_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "terms-of-use" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "brain.head.profile",
                                title: locManager.t("settings.data_ai_usage"),
                                subtitle: locManager.t("settings.data_ai_usage_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "data-privacy" }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "shippingbox.circle.fill",
                                title: locManager.t("settings.acknowledgements"),
                                subtitle: locManager.t("settings.acknowledgements_sub"),
                                showArrow: true,
                                onTap: { selectedTab = "acknowledgements" }
                            )
                        }

                    }
                    .padding(.vertical, AppTheme.Spacing.lg)
                }

            }
            .sheet(item: $activeWebDestination) { destination in
                LegalWebViewSheet(destination: destination)
            }
            .confirmationDialog(
                locManager.t("support.mail_unavailable_title"),
                isPresented: $showMailFallback,
                titleVisibility: .visible
            ) {
                Button(locManager.t("support.copy_email")) {
                    ExternalNavigator.copySupportEmail()
                }
                Button(locManager.t("about.website")) {
                    activeWebDestination = .website
                }
                Button(locManager.t("common.cancel"), role: .cancel) { }
            } message: {
                Text(locManager.t("support.mail_unavailable_message", AppConstants.Links.supportEmail))
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
            .echoCard(colorScheme)
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

    private let iconWidth: CGFloat = AppTheme.Layout.compactControlHeight
    private let rowSpacing: CGFloat = AppTheme.Spacing.md

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: rowSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .echoIconContainer(AppTheme.Colors.accent, size: iconWidth)

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
        .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}
