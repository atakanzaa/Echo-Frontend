import AuthenticationServices
import Foundation
import UIKit

struct AppleSignInResult {
    let identityToken: String
    let authorizationCode: String
    let displayName: String?
}

@MainActor
final class AppleSignInManager: NSObject {
    static let shared = AppleSignInManager()

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var controller: ASAuthorizationController?

    private override init() {}

    func signIn() async throws -> AppleSignInResult {
        guard continuation == nil else {
            throw AppleSignInManagerError.signInAlreadyInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    private func finish(with result: Result<AppleSignInResult, Error>) {
        let continuation = continuation
        self.continuation = nil
        self.controller = nil

        switch result {
        case .success(let value):
            continuation?.resume(returning: value)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(AppleSignInManagerError.invalidCredential))
            return
        }

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              !identityToken.isEmpty else {
            finish(with: .failure(AppleSignInManagerError.missingIdentityToken))
            return
        }

        guard let authorizationCodeData = credential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8),
              !authorizationCode.isEmpty else {
            finish(with: .failure(AppleSignInManagerError.missingAuthorizationCode))
            return
        }

        let formattedName = credential.fullName.map {
            PersonNameComponentsFormatter().string(from: $0)
        }?.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = AppleSignInResult(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            displayName: formattedName?.isEmpty == false ? formattedName : nil
        )
        finish(with: .success(result))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            finish(with: .failure(AppleSignInManagerError.cancelled))
        } else {
            finish(with: .failure(error))
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        keyWindow() ?? ASPresentationAnchor()
    }
}

enum AppleSignInManagerError: LocalizedError {
    case signInAlreadyInProgress
    case cancelled
    case invalidCredential
    case missingIdentityToken
    case missingAuthorizationCode

    var errorDescription: String? {
        let loc = LocalizationManager.shared
        switch self {
        case .signInAlreadyInProgress:
            return loc.t("auth.apple_in_progress")
        case .cancelled:
            return loc.t("auth.apple_cancelled")
        case .invalidCredential, .missingIdentityToken, .missingAuthorizationCode:
            return loc.t("auth.apple_failed")
        }
    }
}
