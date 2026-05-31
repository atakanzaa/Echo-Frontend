import SwiftUI

struct HelpSupportView: View {
    @Binding var selectedTab: AppTab
    @State private var expandedQuestion: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    @State private var searchText = ""
    @State private var activeWebDestination: WebDestination?
    @State private var showMailFallback = false

    private var faqs: [(id: String, q: String, a: String)] {
        [
            (id: "1", q: locManager.t("help.faq1_q"), a: locManager.t("help.faq1_a")),
            (id: "2", q: locManager.t("help.faq2_q"), a: locManager.t("help.faq2_a")),
            (id: "3", q: locManager.t("help.faq3_q"), a: locManager.t("help.faq3_a")),
            (id: "4", q: locManager.t("help.faq4_q"), a: locManager.t("help.faq4_a")),
            (id: "5", q: locManager.t("help.faq5_q"), a: locManager.t("help.faq5_a")),
            (id: "6", q: locManager.t("help.faq6_q"), a: locManager.t("help.faq6_a")),
        ]
    }

    private var filteredFaqs: [(id: String, q: String, a: String)] {
        searchText.isEmpty ? faqs :
            faqs.filter {
                $0.q.localizedCaseInsensitiveContains(searchText) ||
                $0.a.localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                DetailScreenHeader(
                    title: locManager.t("nav.help_support"),
                    selectedTab: $selectedTab,
                    fallback: .settings
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.Colors.accent.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppTheme.Colors.accent)
                            }

                            Text(locManager.t("help.how_can_we_help"))
                                .font(AppTheme.Typography.heading2)
                                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                            Text(locManager.t("help.find_answers"))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, AppTheme.Spacing.sm)

                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

                            TextField(locManager.t("help.search_placeholder"), text: $searchText)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.surface(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                        .padding(.horizontal, AppTheme.Spacing.md)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(locManager.t("help.frequently_asked"))
                                .font(AppTheme.Typography.label).fontWeight(.bold)
                                .tracking(0.6)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                .padding(.horizontal, AppTheme.Spacing.md)

                            VStack(spacing: 0) {
                                if filteredFaqs.isEmpty {
                                    EmptySupportSearchView(
                                        title: locManager.t("help.no_results_title"),
                                        subtitle: locManager.t("help.no_results_subtitle")
                                    )
                                } else {
                                    ForEach(Array(filteredFaqs.enumerated()), id: \.element.id) { index, faq in
                                        if index > 0 {
                                            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                                        }

                                        FAQRow(
                                            question: faq.q,
                                            answer: faq.a,
                                            isExpanded: expandedQuestion == faq.id,
                                            onTap: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    expandedQuestion = expandedQuestion == faq.id ? nil : faq.id
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .echoSectionContent()
                            .background(AppTheme.Colors.surfaceElevated(colorScheme))
                            .cornerRadius(AppTheme.Spacing.radiusLg)
                            .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(locManager.t("help.quick_actions"))
                                .font(AppTheme.Typography.label).fontWeight(.bold)
                                .tracking(0.6)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                .padding(.horizontal, AppTheme.Spacing.md)

                            VStack(spacing: 0) {
                                ContactRow(
                                    icon: "envelope.fill",
                                    iconColor: AppTheme.Colors.accent,
                                    title: locManager.t("settings.contact_support"),
                                    subtitle: locManager.t("settings.contact_support_sub"),
                                    action: {
                                        if !ExternalNavigator.openSupportAction(.contactSupport, localization: locManager) {
                                            showMailFallback = true
                                        }
                                    }
                                )

                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                                ContactRow(
                                    icon: "exclamationmark.bubble.fill",
                                    iconColor: AppTheme.Colors.destructive,
                                    title: locManager.t("settings.report_problem"),
                                    subtitle: locManager.t("settings.report_problem_sub"),
                                    action: {
                                        if !ExternalNavigator.openSupportAction(.reportProblem, localization: locManager) {
                                            showMailFallback = true
                                        }
                                    }
                                )

                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                                ContactRow(
                                    icon: "bubble.left.and.text.bubble.right.fill",
                                    iconColor: AppTheme.Colors.moodVeryPositive,
                                    title: locManager.t("settings.send_feedback"),
                                    subtitle: locManager.t("settings.send_feedback_sub"),
                                    action: {
                                        if !ExternalNavigator.openSupportAction(.sendFeedback, localization: locManager) {
                                            showMailFallback = true
                                        }
                                    }
                                )

                                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

                                ContactRow(
                                    icon: "star.fill",
                                    iconColor: AppTheme.Colors.gold,
                                    title: locManager.t("help.rate_echo"),
                                    subtitle: locManager.t("help.rate_echo_sub"),
                                    action: { ExternalNavigator.requestAppReview() }
                                )
                            }
                            .echoSectionContent()
                            .background(AppTheme.Colors.surfaceElevated(colorScheme))
                            .cornerRadius(AppTheme.Spacing.radiusLg)
                            .padding(.horizontal, AppTheme.Spacing.md)
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

private struct FAQRow: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(question)
                        .font(AppTheme.Typography.caption).fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                if isExpanded {
                    Text(answer)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 10)
        }
    }
}

private struct ContactRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
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

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight)
            .padding(.vertical, 4)
        }
    }
}

private struct EmptySupportSearchView: View {
    let title: String
    let subtitle: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

            Text(subtitle)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
    }
}
