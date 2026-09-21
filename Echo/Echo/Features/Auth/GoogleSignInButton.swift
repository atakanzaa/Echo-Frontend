import GoogleSignIn
import SwiftUI
import UIKit

/// Google ile giriş (rules.md §2). SDK'dan alınan `id_token` backend'e gönderilir.
struct GoogleSignInButton: View {
    var variant: EchoButtonVariant = .tertiary
    @Environment(AppEnvironment.self) private var environment
    @State private var error: AppError?
    @State private var isWorking = false

    var body: some View {
        VStack(spacing: AppTheme.space.xxs) {
            EchoButton("welcome.continueWithGoogle", variant: variant, size: .lg,
                       leadingIcon: "g.circle", fullWidth: true, isLoading: isWorking) { start() }
            if let error, let message = error.serverMessage {

                Text(message)
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.feedback.danger)
            }
        }
    }

    private func start() {
        guard let presenter = UIApplication.shared.topViewController else { return }
        isWorking = true
        error = nil
        GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, signInError in
            Task { @MainActor in
                guard let idToken = result?.user.idToken?.tokenString else {
                    isWorking = false
                    // İptal sessizdir; diğer hatalar genel mesajla gösterilir.
                    if signInError != nil { error = .unexpectedResponse(status: nil) }
                    return
                }
                do {
                    try await environment.session.signInWithGoogle(idToken: idToken,
                                                                   timezone: TimeZone.current.identifier,
                                                                   language: environment.language.language)
                } catch {
                    self.error = AppError.displayable(error)
                }
                isWorking = false
            }
        }
    }
}

extension UIApplication {
    /// Google SDK'sının sunum için ihtiyaç duyduğu görünen view controller.
    var topViewController: UIViewController? {
        let scene = connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        var controller = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }
}
