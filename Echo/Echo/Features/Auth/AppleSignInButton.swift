import AuthenticationServices
import CryptoKit
import SwiftUI

/// Apple ile giriş (rules.md §2). Uygulama rastgele bir raw nonce üretir, Apple'a SHA-256 özetini verir,
/// backend'e `identity_token` ile ham nonce'u gönderir.
struct AppleSignInButton: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.colorScheme) private var colorScheme
    @State private var rawNonce = AppleNonce.make()
    @State private var error: AppError?

    var body: some View {
        VStack(spacing: AppTheme.space.xxs) {
            SignInWithAppleButton(.continue) { request in

                rawNonce = AppleNonce.make()
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleNonce.sha256(rawNonce)
            } onCompletion: { result in

                handle(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous))
            if let error, let message = error.serverMessage {

                Text(message)
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.feedback.danger)
            }
        }
    }

    private func handle(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                error = .unexpectedResponse(status: nil)
                return
            }
            // Ad yalnız ilk yetkilendirmede gelir; sonraki girişlerde null olması normaldir.
            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            Task {
                do {
                    try await environment.session.signInWithApple(identityToken: identityToken,
                                                                  rawNonce: rawNonce,
                                                                  displayName: displayName.isEmpty ? nil : displayName,
                                                                  timezone: TimeZone.current.identifier,
                                                                  language: environment.language.language)
                } catch {
                    self.error = AppError.from(error)
                }
            }
        case .failure(let failure):
            // Kullanıcı vazgeçtiyse hata gösterilmez.
            if (failure as? ASAuthorizationError)?.code == .canceled { return }
            error = .unexpectedResponse(status: nil)
        }
    }
}

nonisolated enum AppleNonce {
    static func make(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
