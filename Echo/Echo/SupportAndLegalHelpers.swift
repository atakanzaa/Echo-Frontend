import SwiftUI
import SafariServices
import StoreKit
import UIKit

enum WebDestination: Identifiable, Equatable {
    case website
    case custom(title: String, url: URL)

    var id: String {
        switch self {
        case .website:
            return "website"
        case .custom(let title, _):
            return "custom-\(title)"
        }
    }

    var title: String {
        switch self {
        case .website:
            return LocalizationManager.shared.t("about.website")
        case .custom(let title, _):
            return title
        }
    }

    var url: URL {
        switch self {
        case .website:
            return AppConstants.Links.website
        case .custom(_, let url):
            return url
        }
    }
}

enum SupportActionKind: String, Identifiable {
    case contactSupport
    case reportProblem
    case sendFeedback

    var id: String { rawValue }

    func mailtoURL(localization: LocalizationManager) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppConstants.Links.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject(localization: localization)),
            URLQueryItem(name: "body", value: body(localization: localization))
        ]
        return components.url
    }

    private func subject(localization: LocalizationManager) -> String {
        switch self {
        case .contactSupport:
            return localization.t("support.contact_subject")
        case .reportProblem:
            return localization.t("support.report_subject")
        case .sendFeedback:
            return localization.t("support.feedback_subject")
        }
    }

    private func intro(localization: LocalizationManager) -> String {
        switch self {
        case .contactSupport:
            return localization.t("support.contact_body_intro")
        case .reportProblem:
            return localization.t("support.report_body_intro")
        case .sendFeedback:
            return localization.t("support.feedback_body_intro")
        }
    }

    private func body(localization: LocalizationManager) -> String {
        [
            intro(localization: localization),
            "",
            "\(localization.t("support.email_body_version")): \(AppConstants.AppInfo.shortVersion)",
            "\(localization.t("support.email_body_build")): \(AppConstants.AppInfo.buildNumber)",
            "\(localization.t("support.email_body_ios")): \(UIDevice.current.systemVersion)",
            "\(localization.t("support.email_body_device")): \(UIDevice.current.model)",
            "",
            localization.t("support.email_body_details")
        ].joined(separator: "\n")
    }
}

@MainActor
enum ExternalNavigator {
    static func openSupportAction(_ action: SupportActionKind, localization: LocalizationManager) -> Bool {
        guard let url = action.mailtoURL(localization: localization),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }

        UIApplication.shared.open(url)
        return true
    }

    static func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }

    static func requestAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            SKStoreReviewController.requestReview(in: windowScene)
            return
        }

        guard let fallbackURL = AppConstants.Links.appStoreReviewURL else { return }
        UIApplication.shared.open(fallbackURL)
    }

    static func copySupportEmail() {
        UIPasteboard.general.string = AppConstants.Links.supportEmail
    }
}

struct LegalWebViewSheet: UIViewControllerRepresentable {
    let destination: WebDestination

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let controller = SFSafariViewController(url: destination.url, configuration: configuration)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct DetailScreenHeader: View {
    let title: String
    @Binding var selectedTab: String
    let fallback: String

    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppScreenHeader(
            title: title,
            showBack: true,
            onBack: {
                selectedTab = tabNavigation.goBack(from: selectedTab, fallback: fallback)
            }
        )
    }
}

struct AppVersionFooter: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(AppConstants.AppInfo.footerVersionLabel)
            .font(AppTheme.Typography.micro)
            .foregroundColor(AppTheme.Colors.textDisabled(colorScheme))
            .padding(.bottom, AppTheme.Spacing.xxl)
    }
}
