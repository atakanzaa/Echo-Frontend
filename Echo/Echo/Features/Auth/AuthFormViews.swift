import SwiftUI

/// Giriş formu. 401 burada form hatasıdır; oturum yenileme başlatmaz (rules.md §2).
struct SignInView: View {
    let onForgotPassword: () -> Void
    let onSignUp: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var email: String
    @State private var password = ""
    @State private var error: AppError?
    @State private var isWorking = false

    init(initialEmail: String = "", onForgotPassword: @escaping () -> Void, onSignUp: @escaping () -> Void) {
        self.onForgotPassword = onForgotPassword
        self.onSignUp = onSignUp
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        AuthScaffold(title: "auth.signInTitle", error: error) {
            EchoTextField("auth.email", placeholder: "auth.emailPlaceholder", text: $email,
                          errorText: fieldError("email"), contentType: .emailAddress, keyboardType: .emailAddress)
            EchoTextField("auth.password", text: $password, isSecure: true,
                          errorText: fieldError("password"), contentType: .password, submitLabel: .go)
            EchoButton("welcome.signIn", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                .disabled(email.isEmpty || password.isEmpty)
            EchoButton("auth.forgotPassword", variant: .ghost, size: .sm, action: onForgotPassword)
            AuthSwitchPrompt(question: "auth.noAccount", action: "auth.signUpAction", onTap: onSignUp)
        }
    }

    private func fieldError(_ field: String) -> String? {
        error?.problem?.fieldError(field) != nil ? error?.problem?.detail : nil
    }

    private func submit() {
        isWorking = true
        error = nil
        Task {
            do {
                try await environment.session.signIn(email: email, password: password)
            } catch {
                self.error = AppError.displayable(error)
            }
            isWorking = false
        }
    }
}

/// Kayıt formu. `timezone` cihazdan, `language` uygulama dilinden gönderilir.
struct SignUpView: View {
    /// Kayıtlı bir e-postayla gelindiyse girişe o e-postayla geçilir.
    let onSignIn: (String?) -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var error: AppError?
    @State private var isWorking = false

    var body: some View {
        AuthScaffold(title: "auth.signUpTitle", error: error) {
            if error == nil, let closed = environment.remoteConfig.notice("registrations_closed") {

                EchoBanner(kind: .warning, title: closed.message)
            }
            EchoTextField("auth.displayName", text: $displayName, errorText: fieldError("display_name"), contentType: .name)
            EchoTextField("auth.email", placeholder: "auth.emailPlaceholder", text: $email,
                          errorText: fieldError("email"), contentType: .emailAddress, keyboardType: .emailAddress)
            EchoTextField("auth.password", text: $password, isSecure: true,
                          errorText: fieldError("password"), contentType: .newPassword)
            EchoButton("welcome.createAccount", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                .disabled(email.isEmpty || password.isEmpty || displayName.isEmpty)
            if error?.problem?.code == "EMAIL_ALREADY_REGISTERED" {

                EchoButton("auth.signInWithThisEmail", variant: .secondary, size: .lg, fullWidth: true) { onSignIn(email) }
            }
            AuthSwitchPrompt(question: "auth.haveAccount", action: "auth.signInAction", onTap: { onSignIn(nil) })
        }
    }

    private func fieldError(_ field: String) -> String? {
        error?.problem?.fieldError(field) != nil ? error?.problem?.detail : nil
    }

    private func submit() {
        isWorking = true
        error = nil
        Task {
            do {
                try await environment.session.register(email: email, password: password, displayName: displayName,
                                                       timezone: TimeZone.current.identifier,
                                                       language: environment.language.language)
            } catch {
                self.error = AppError.displayable(error)
            }
            isWorking = false
        }
    }
}

/// Şifre sıfırlama isteği. E-postanın kayıtlı olup olmadığı gösterilmez.
struct ForgotPasswordView: View {
    let onCodeSent: (String) -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var email = ""
    @State private var error: AppError?
    @State private var isWorking = false

    var body: some View {
        AuthScaffold(title: "auth.forgotTitle", error: error) {
            Text("auth.forgotBody")
                .echoTextStyle(.callout)
                .foregroundStyle(AppTheme.color.content.secondary)
            EchoTextField("auth.email", placeholder: "auth.emailPlaceholder", text: $email,
                          contentType: .emailAddress, keyboardType: .emailAddress)
            EchoButton("auth.sendCode", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                .disabled(email.isEmpty)
        }
    }

    private func submit() {
        isWorking = true
        error = nil
        Task {
            do {
                try await environment.auth.requestPasswordReset(email: email)
                onCodeSent(email)
            } catch {
                self.error = AppError.displayable(error)
            }
            isWorking = false
        }
    }
}

/// Kod ile şifre sıfırlama.
struct ResetPasswordView: View {
    let email: String
    let onFinished: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var code = ""
    @State private var newPassword = ""
    @State private var error: AppError?
    @State private var isWorking = false
    @State private var isDone = false

    var body: some View {
        AuthScaffold(title: "auth.resetTitle", error: error) {
            if isDone {

                EchoBanner(kind: .success, title: String(localized: "auth.resetDone"))
            }
            EchoTextField("auth.resetCode", text: $code, errorText: fieldError("code"), keyboardType: .numberPad)
            EchoTextField("auth.newPassword", text: $newPassword, isSecure: true,
                          errorText: fieldError("new_password"), contentType: .newPassword)
            EchoButton("auth.resetAction", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                .disabled(code.isEmpty || newPassword.isEmpty)
        }
    }

    private func fieldError(_ field: String) -> String? {
        error?.problem?.fieldError(field) != nil ? error?.problem?.detail : nil
    }

    private func submit() {
        isWorking = true
        error = nil
        Task {
            do {
                try await environment.auth.resetPassword(email: email, code: code, newPassword: newPassword)
                isDone = true
                onFinished()
            } catch {
                self.error = AppError.displayable(error)
            }
            isWorking = false
        }
    }
}

/// Form ekranlarının ortak iskeleti: yumuşak aurora zemin, yankı işareti, cam kart içinde alanlar.
struct AuthScaffold<Content: View>: View {
    let title: LocalizedStringKey
    let error: AppError?
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            EchoAuroraBackground(style: .soft)
            ScrollView {
                VStack(spacing: AppTheme.space.md) {
                    EchoBrandMark(size: 120, tint: AppTheme.color.accent.primary)
                        .padding(.top, AppTheme.space.xs)
                    VStack(alignment: .leading, spacing: AppTheme.space.sm) {
                        Text(title)
                            .echoTextStyle(.title2)
                            .foregroundStyle(AppTheme.color.content.primary)
                        if let error, let message = error.serverMessage ?? error.messageKey.map({ String(localized: String.LocalizationValue($0)) }) {

                            EchoBanner(kind: .danger, title: message)
                        }
                        content
                    }
                    .padding(AppTheme.space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.radius.xl, style: .continuous)
                            .fill(AppTheme.color.bg.surface)
                            .echoSurface(.level2, in: RoundedRectangle(cornerRadius: AppTheme.radius.xl, style: .continuous))
                    }
                }
                .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
                .padding(.bottom, AppTheme.space.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

/// "Hesabın yok mu? Kayıt ol" gibi ekranlar arası geçiş satırı.
struct AuthSwitchPrompt: View {
    let question: LocalizedStringKey
    let action: LocalizedStringKey
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.space.xxxs) {
            Text(question)
                .echoTextStyle(.subhead)
                .foregroundStyle(AppTheme.color.content.secondary)
            Button(action: onTap) {
                Text(action)
                    .echoTextStyle(.bodyEmphasis)
                    .foregroundStyle(AppTheme.color.content.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.space.xxs)
    }
}
