import SwiftUI

/// Kimlik doğrulama akışı: karşılama → giriş / kayıt / şifre sıfırlama (rules.md §2).
struct AuthFlowView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var path = NavigationPath()

    private nonisolated enum Route: Hashable {
        case signIn
        case signUp
        case forgotPassword
        case resetPassword(email: String)
    }

    var body: some View {
        NavigationStack(path: $path) {
            welcome
                .navigationDestination(for: Route.self) { route in

                    switch route {
                    case .signIn: SignInView { path.append(Route.forgotPassword) }
                    case .signUp: SignUpView()
                    case .forgotPassword: ForgotPasswordView { email in path.append(Route.resetPassword(email: email)) }
                    case .resetPassword(let email): ResetPasswordView(email: email) { path = NavigationPath() }
                    }
                }
        }
    }

    private var welcome: some View {
        VStack(spacing: AppTheme.space.lg) {
            Spacer()
            EchoRippleView(ringCount: 4, intensity: 0.7)
                .frame(width: 160, height: 160)
            VStack(spacing: AppTheme.space.xs) {
                Text("welcome.title")
                    .echoTextStyle(.title1)
                    .foregroundStyle(AppTheme.color.content.primary)
                Text("welcome.subtitle")
                    .echoTextStyle(.callout)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: AppTheme.space.xs) {
                AppleSignInButton()
                GoogleSignInButton()
                EchoButton("welcome.signIn", variant: .tertiary, size: .lg, fullWidth: true) { path.append(Route.signIn) }
                EchoButton("welcome.createAccount", variant: .ghost, size: .md, fullWidth: true) { path.append(Route.signUp) }
            }
            legal
        }
        .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
        .padding(.bottom, AppTheme.space.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
    }

    /// Bağlantılar `app/config`'ten gelir; null gelen bağlantı gizlenir.
    private var legal: some View {
        VStack(spacing: AppTheme.space.xxxs) {
            Text("welcome.legal")
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: AppTheme.space.sm) {
                if let terms = environment.remoteConfig.config?.termsURL {

                    Link(destination: terms) { Text("welcome.terms").echoTextStyle(.caption) }
                }
                if let privacy = environment.remoteConfig.config?.privacyPolicyURL {

                    Link(destination: privacy) { Text("welcome.privacy").echoTextStyle(.caption) }
                }
            }
            .foregroundStyle(AppTheme.color.content.accent)
        }
    }
}
