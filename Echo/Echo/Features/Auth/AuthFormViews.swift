import SwiftUI

/// Giriş formu. 401 burada form hatasıdır; oturum yenileme başlatmaz (rules.md §2).
struct SignInView: View {
    let onForgotPassword: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var email = ""
    @State private var password = ""
    @State private var error: AppError?
    @State private var isWorking = false

    var body: some View {
        AuthScaffold(title: "auth.signInTitle", error: error) {
            EchoTextField("auth.email", placeholder: "auth.emailPlaceholder", text: $email,
                          errorText: fieldError("email"), contentType: .emailAddress, keyboardType: .emailAddress)
            EchoTextField("auth.password", text: $password, isSecure: true,
                          errorText: fieldError("password"), contentType: .password, submitLabel: .go)
            EchoButton("welcome.signIn", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                .disabled(email.isEmpty || password.isEmpty)
            EchoButton("auth.forgotPassword", variant: .ghost, size: .sm, action: onForgotPassword)
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
                self.error = AppError.from(error)
            }
            isWorking = false
        }
    }
}

/// Kayıt formu. `timezone` cihazdan, `language` uygulama dilinden gönderilir.
struct SignUpView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var error: AppError?
    @State private var isWorking = false

    var body: some View {
        AuthScaffold(title: "auth.signUpTitle", error: error) {
            EchoTextField("auth.displayName", text: $displayName, errorText: fieldError("display_name"), contentType: .name)
            EchoTextField("auth.email", placeholder: "auth.emailPlaceholder", text: $email,
                          errorText: fieldError("email"), contentType: .emailAddress, keyboardType: .emailAddress)
            EchoTextField("auth.password", text: $password, isSecure: true,
                          errorText: fieldError("password"), contentType: .newPassword)
            EchoButton("welcome.createAccount", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                .disabled(email.isEmpty || password.isEmpty || displayName.isEmpty)
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
                self.error = AppError.from(error)
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
                self.error = AppError.from(error)
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
                self.error = AppError.from(error)
            }
            isWorking = false
        }
    }
}

/// Form ekranlarının ortak iskeleti: başlık, sunucu hatası ve alanlar.
struct AuthScaffold<Content: View>: View {
    let title: LocalizedStringKey
    let error: AppError?
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.space.sm) {
                Text(title)
                    .echoTextStyle(.title2)
                    .foregroundStyle(AppTheme.color.content.primary)
                if let error, let message = error.serverMessage ?? error.messageKey.map({ String(localized: String.LocalizationValue($0)) }) {

                    EchoBanner(kind: .danger, title: message)
                }
                content
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
        }
        .background(AppTheme.color.bg.canvas)
        .scrollDismissesKeyboard(.interactively)
    }
}
