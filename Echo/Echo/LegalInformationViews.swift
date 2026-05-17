import SwiftUI

struct AboutAppView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var activeWebDestination: WebDestination?
    @State private var showMailFallback = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                DetailScreenHeader(
                    title: locManager.t("about.title"),
                    selectedTab: $selectedTab,
                    fallback: "settings"
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SettingsSectionView(title: locManager.t("about.summary")) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text(AppConstants.Brand.companyDisplayName)
                                    .font(AppTheme.Typography.heading3)
                                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                                Text(locManager.t("about.description"))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AppTheme.Spacing.xs)
                        }

                        SettingsSectionView(title: locManager.t("about.company")) {
                            SettingsStaticItemView(
                                icon: "building.2.fill",
                                title: locManager.t("about.developer"),
                                subtitle: AppConstants.Brand.companyDisplayName
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "globe",
                                title: locManager.t("about.website"),
                                subtitle: AppConstants.Links.website.absoluteString,
                                showArrow: true,
                                onTap: { activeWebDestination = .website }
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "envelope.circle.fill",
                                title: locManager.t("about.support_email"),
                                subtitle: AppConstants.Links.supportEmail,
                                showArrow: true,
                                onTap: {
                                    if !ExternalNavigator.openSupportAction(.contactSupport, localization: locManager) {
                                        showMailFallback = true
                                    }
                                }
                            )
                        }

                        SettingsSectionView(title: locManager.t("about.app_details")) {
                            SettingsStaticItemView(
                                icon: "info.circle.fill",
                                title: locManager.t("settings.app_version"),
                                subtitle: AppConstants.AppInfo.fullVersionLabel
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsStaticItemView(
                                icon: "number.circle.fill",
                                title: locManager.t("about.build_number"),
                                subtitle: AppConstants.AppInfo.buildNumber
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsStaticItemView(
                                icon: "shippingbox.circle.fill",
                                title: locManager.t("about.bundle_identifier"),
                                subtitle: AppConstants.AppInfo.bundleIdentifier
                            )
                        }

                        AppVersionFooter()
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                }
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
            Button(locManager.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(locManager.t("support.mail_unavailable_message", AppConstants.Links.supportEmail))
        }
    }
}

struct DataAndAIUsageView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                DetailScreenHeader(
                    title: locManager.t("privacy.title"),
                    selectedTab: $selectedTab,
                    fallback: "settings"
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SettingsSectionView(title: locManager.t("privacy.permissions")) {
                            InfoBodyRow(
                                title: locManager.t("privacy.permissions_mic_title"),
                                content: locManager.t("privacy.permissions_mic_body")
                            )
                        }

                        SettingsSectionView(title: locManager.t("privacy.feature_usage")) {
                            VStack(spacing: 0) {
                                InfoBodyRow(
                                    title: locManager.t("privacy.feature_journal_title"),
                                    content: locManager.t("privacy.feature_journal_body")
                                )

                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                                InfoBodyRow(
                                    title: locManager.t("privacy.feature_ai_title"),
                                    content: locManager.t("privacy.feature_ai_body")
                                )
                            }
                        }

                        SettingsSectionView(title: locManager.t("privacy.account_data")) {
                            InfoBodyRow(
                                title: locManager.t("privacy.account_data_title"),
                                content: locManager.t("privacy.account_data_body")
                            )
                        }

                        SettingsSectionView(title: locManager.t("privacy.controls")) {
                            InfoBodyRow(
                                title: locManager.t("privacy.controls_title"),
                                content: locManager.t("privacy.controls_body")
                            )
                        }

                        AppVersionFooter()
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                }
            }
        }
    }
}

enum NativeLegalDestination: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .terms:
            return "legal.terms.title"
        case .privacy:
            return "legal.privacy.title"
        }
    }

    var sections: [(titleKey: String, bodyKey: String)] {
        switch self {
        case .terms:
            return [
                ("legal.terms.acceptance", "legal.terms.acceptance_body"),
                ("legal.terms.account", "legal.terms.account_body"),
                ("legal.terms.subscriptions", "legal.terms.subscriptions_body"),
                ("legal.terms.community", "legal.terms.community_body"),
                ("legal.terms.ai", "legal.terms.ai_body"),
                ("legal.terms.data", "legal.terms.data_body"),
                ("legal.terms.termination", "legal.terms.termination_body"),
                ("legal.terms.contact", "legal.terms.contact_body")
            ]
        case .privacy:
            return [
                ("legal.privacy.collected", "legal.privacy.collected_body"),
                ("legal.privacy.journal", "legal.privacy.journal_body"),
                ("legal.privacy.ai", "legal.privacy.ai_body"),
                ("legal.privacy.community", "legal.privacy.community_body"),
                ("legal.privacy.notifications", "legal.privacy.notifications_body"),
                ("legal.privacy.retention", "legal.privacy.retention_body"),
                ("legal.privacy.contact", "legal.privacy.contact_body")
            ]
        }
    }
}

struct NativeLegalSheet: View {
    let destination: NativeLegalDestination

    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                ScrollView {
                    LegalPolicyContent(destination: destination)
                        .padding(.top, AppTheme.Spacing.sm)
                        .padding(.bottom, AppTheme.Layout.sheetBottomInset)
                }
            }
            .navigationTitle(locManager.t(destination.titleKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(locManager.t("common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsOfUseView: View {
    @Binding var selectedTab: String

    var body: some View {
        LegalPolicyPage(
            destination: .terms,
            selectedTab: $selectedTab,
            fallback: "settings"
        )
    }
}

struct PrivacyPolicyView: View {
    @Binding var selectedTab: String

    var body: some View {
        LegalPolicyPage(
            destination: .privacy,
            selectedTab: $selectedTab,
            fallback: "settings"
        )
    }
}

private struct LegalPolicyPage: View {
    let destination: NativeLegalDestination
    @Binding var selectedTab: String
    let fallback: String

    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                DetailScreenHeader(
                    title: locManager.t(destination.titleKey),
                    selectedTab: $selectedTab,
                    fallback: fallback
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        LegalPolicyContent(destination: destination)
                        AppVersionFooter()
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                }
            }
        }
    }
}

private struct LegalPolicyContent: View {
    let destination: NativeLegalDestination

    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ForEach(Array(destination.sections.enumerated()), id: \.offset) { _, section in
                SettingsSectionView(title: locManager.t(section.titleKey)) {
                    Text(locManager.t(section.bodyKey))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
            }
        }
    }
}

struct AcknowledgementsView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var activeWebDestination: WebDestination?

    // swiftlint:disable:next force_unwrapping
    private let googleSignInRepository: URL = URL(string: "https://github.com/google/GoogleSignIn-iOS")!

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                DetailScreenHeader(
                    title: locManager.t("ack.title"),
                    selectedTab: $selectedTab,
                    fallback: "settings"
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SettingsSectionView(title: locManager.t("ack.section_title")) {
                            SettingsStaticItemView(
                                icon: "shippingbox.circle.fill",
                                title: "GoogleSignIn-iOS",
                                subtitle: locManager.t("ack.google_sign_in_sub")
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsStaticItemView(
                                icon: "building.2.crop.circle.fill",
                                title: locManager.t("ack.provider"),
                                subtitle: "Google LLC"
                            )

                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                            SettingsItemView(
                                icon: "link.circle.fill",
                                title: locManager.t("ack.source_repository"),
                                subtitle: googleSignInRepository.absoluteString,
                                showArrow: true,
                                onTap: {
                                    activeWebDestination = .custom(
                                        title: "GoogleSignIn-iOS",
                                        url: googleSignInRepository
                                    )
                                }
                            )
                        }

                        AppVersionFooter()
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                }
            }
        }
        .sheet(item: $activeWebDestination) { destination in
            LegalWebViewSheet(destination: destination)
        }
    }
}

private struct InfoBodyRow: View {
    let title: String
    let content: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

            Text(content)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}
