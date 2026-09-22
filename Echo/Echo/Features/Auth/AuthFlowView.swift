import SwiftUI

/// Kimlik doğrulama akışı: karşılama → giriş / kayıt / şifre sıfırlama (rules.md §2).
/// Zemin Echo'nun yankı motifini taşır; hareket Reduce Motion'da durur.
struct AuthFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var path = NavigationPath()

    private nonisolated enum Route: Hashable {
        /// `email` kayıttan "bu e-posta kayıtlı" ile gelindiğinde girişi doldurur.
        case signIn(email: String?)
        case signUp
        case forgotPassword
        case resetPassword(email: String)
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(onSignIn: { path.append(Route.signIn(email: nil)) },
                        onSignUp: { path.append(Route.signUp) })
                .navigationDestination(for: Route.self) { route in

                    switch route {
                    case .signIn(let email):
                        SignInView(initialEmail: email ?? "",
                                   onForgotPassword: { path.append(Route.forgotPassword) },
                                   onSignUp: { path.append(Route.signUp) })
                    case .signUp:
                        SignUpView(onSignIn: { email in path.append(Route.signIn(email: email)) })
                    case .forgotPassword:
                        ForgotPasswordView { email in path.append(Route.resetPassword(email: email)) }
                    case .resetPassword(let email):
                        ResetPasswordView(email: email) { path = NavigationPath() }
                    }
                }
        }
    }
}

/// Karşılama: tam ekran aurora, nefes alan yankı işareti ve tek birincil eylem.
struct WelcomeView: View {
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        ZStack {
            EchoAuroraBackground(style: .immersive)
            VStack(spacing: 0) {
                Spacer(minLength: AppTheme.space.xl)
                EchoBrandMark(size: 220)
                    .padding(.bottom, AppTheme.space.lg)
                VStack(spacing: AppTheme.space.xs) {
                    Text("welcome.title")
                        .echoTextStyle(.display)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("welcome.subtitle")
                        .echoTextStyle(.callout)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.space.sm)
                }
                Spacer(minLength: AppTheme.space.lg)
                if let message = environment.session.endedMessage {

                    EchoBanner(kind: .danger, title: message)
                        .padding(.bottom, AppTheme.space.sm)
                }
                actions
                legal
                    .padding(.top, AppTheme.space.sm)
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.lg)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var actions: some View {
        VStack(spacing: AppTheme.space.xs) {
            AppleSignInButton()
            GoogleSignInButton(variant: .glass)
            EchoButton("welcome.signInWithEmail", variant: .glass, size: .lg, fullWidth: true, action: onSignIn)
            HStack(spacing: AppTheme.space.xxxs) {
                Text("auth.noAccount")
                    .echoTextStyle(.subhead)
                    .foregroundStyle(.white.opacity(0.75))
                Button(action: onSignUp) {
                    Text("auth.signUpAction")
                        .echoTextStyle(.bodyEmphasis)
                        .foregroundStyle(.white)
                        .underline()
                }
            }
            .padding(.top, AppTheme.space.xxxs)
        }
    }

    /// Bağlantılar `app/config`'ten gelir; null gelen bağlantı gizlenir.
    private var legal: some View {
        VStack(spacing: AppTheme.space.xxxs) {
            Text("welcome.legal")
                .echoTextStyle(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            HStack(spacing: AppTheme.space.sm) {
                if let terms = environment.remoteConfig.config?.termsURL {

                    Link(destination: terms) { Text("welcome.terms").echoTextStyle(.caption) }
                }
                if let privacy = environment.remoteConfig.config?.privacyPolicyURL {

                    Link(destination: privacy) { Text("welcome.privacy").echoTextStyle(.caption) }
                }
            }
            .foregroundStyle(.white.opacity(0.85))
        }
    }
}
