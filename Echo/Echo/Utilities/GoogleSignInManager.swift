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
        switch self {
        case .sdkNotInstalled:
            return "Google Sign-In SDK is not installed in Xcode yet."
        case .missingClientId:
            return "Google client ID is missing."
        case .missingPresenter:
            return "Google sign-in could not be presented."
        case .missingIdToken:
            return "Google sign-in did not return an ID token."
        }
    }
}
