import Foundation
import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@MainActor
final class GoogleSignInManager {
    static let shared = GoogleSignInManager()
    private init() {}

    func signInAndGetIdToken() async throws -> String {
        guard !AppConstants.OAuth.googleClientId.isEmpty else {
            throw GoogleSignInManagerError.missingClientId
        }

        #if canImport(GoogleSignIn)
        guard let presentingViewController = topViewController() else {
            throw GoogleSignInManagerError.missingPresenter
        }

        let config = GIDConfiguration(clientID: AppConstants.OAuth.googleClientId)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = result.user.idToken?.tokenString, !idToken.isEmpty else {
            throw GoogleSignInManagerError.missingIdToken
        }
        return idToken
        #else
        throw GoogleSignInManagerError.sdkNotInstalled
        #endif
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController?
        if let base {
            root = base
        } else {
            root = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        }

        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
}

enum GoogleSignInManagerError: LocalizedError {
    case sdkNotInstalled
    case missingClientId
    case missingPresenter
    case missingIdToken

    var errorDescription: String? {
        let loc = LocalizationManager.shared
        switch self {
        case .sdkNotInstalled:
            return loc.t("auth.google_sdk_not_installed")
        case .missingClientId:
            return loc.t("auth.google_client_id_missing")
        case .missingPresenter:
            return loc.t("auth.google_presenter_missing")
        case .missingIdToken:
            return loc.t("auth.google_id_token_missing")
        }
    }
}
