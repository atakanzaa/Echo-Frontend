import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @State private var isSigningUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var agreeToTerms = false
    @State private var showForgotPassword = false
    @State private var activeLegalSheet: NativeLegalDestination?

    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.200, green: 0.090, blue: 0.361),
                    Color(red: 0.078, green: 0.039, blue: 0.114)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            KeyboardAwareFormScroll {
                VStack(spacing: AppTheme.Spacing.lg) {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accent.opacity(0.2))
                                .blur(radius: 30)
                                .frame(width: 120, height: 120)

                            Circle()
                                .fill(AppTheme.Gradients.accent)
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.Colors.accent.opacity(0.5), radius: 20)

                            Image(systemName: "mic.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, AppTheme.Spacing.xxl)

                        Text(isSigningUp ? locManager.t("auth.create_account") : locManager.t("auth.welcome_back"))
                            .font(AppTheme.Typography.heading1)
                            .foregroundColor(.white)

                        Text(locManager.t("auth.tagline"))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, AppTheme.Spacing.sm)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppTheme.Typography.caption).fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: AppTheme.Spacing.sm) {
                        if isSigningUp {
                            authField(label: locManager.t("auth.name"), placeholder: locManager.t("auth.name_placeholder"), text: $displayName)
                        }

                        authField(label: locManager.t("auth.email"), placeholder: locManager.t("auth.email_placeholder"), text: $email, keyboard: .emailAddress)
                        passwordField

                        if isSigningUp {
                            authField(label: locManager.t("auth.confirm_password"), placeholder: locManager.t("auth.confirm_password_placeholder"), text: $confirmPassword, secure: true)
                            termsRow
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    VStack(spacing: AppTheme.Spacing.sm) {
                        if isSigningUp {
                            Button {
                                Task { await viewModel.register(email: email, password: password, displayName: displayName) }
                            } label: {
                                Group {
                                    if viewModel.isLoading { ProgressView().tint(.white) }
                                    else { Text(locManager.t("auth.create_account")).font(AppTheme.Typography.bodyEm) }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(AppTheme.Gradients.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.Spacing.radiusFull)
                            }
                            .disabled(viewModel.isLoading || !agreeToTerms)
                            .opacity(viewModel.isLoading || !agreeToTerms ? 0.65 : 1)
                        } else {
                            Button {
                                Task { await viewModel.login(email: email, password: password) }
                            } label: {
                                Group {
                                    if viewModel.isLoading { ProgressView().tint(.white) }
                                    else { Text(locManager.t("auth.sign_in")).font(AppTheme.Typography.bodyEm) }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(AppTheme.Gradients.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.Spacing.radiusFull)
                            }
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.65 : 1)

                            Button(action: { showForgotPassword = true }) {
                                Text(locManager.t("auth.forgot_password"))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(Color(red: 0.769, green: 0.604, blue: 1.0))
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        Button {
                            Task { await viewModel.loginWithApple() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "applelogo").font(AppTheme.Typography.bodyEm)
                                Text(locManager.t("auth.continue_apple")).font(AppTheme.Typography.bodyEm)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(.white)
                            .foregroundColor(.black)
                            .cornerRadius(AppTheme.Spacing.radiusFull)
                        }
                        .disabled(viewModel.isLoading)

                        Button {
                            Task { await viewModel.loginWithGoogle() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill").font(AppTheme.Typography.bodyEm)
                                Text(locManager.t("auth.continue_google")).font(AppTheme.Typography.bodyEm)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.Spacing.radiusFull)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusFull)
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    HStack(spacing: 4) {
                        Text(isSigningUp ? locManager.t("auth.already_have_account") : locManager.t("auth.no_account"))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.5))

                        Button(action: { isSigningUp.toggle() }) {
                            Text(isSigningUp ? locManager.t("auth.log_in") : locManager.t("auth.sign_up"))
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.769, green: 0.604, blue: 1.0))
                        }
                    }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Button(action: { activeLegalSheet = .terms }) {
                            Text(locManager.t("auth.terms"))
                                .font(AppTheme.Typography.micro)
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Text("•").foregroundColor(.white.opacity(0.2))
                        Button(action: { activeLegalSheet = .privacy }) {
                            Text(locManager.t("auth.privacy"))
                                .font(AppTheme.Typography.micro)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(locManager)
        }
        .sheet(item: $activeLegalSheet) { destination in
            NativeLegalSheet(destination: destination)
                .environmentObject(locManager)
        }
    }

    private func authField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTheme.Typography.label).fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                }
            }
            .font(AppTheme.Typography.body)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
            .background(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(AppTheme.Spacing.radiusMd)
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(locManager.t("auth.password"))
                .font(AppTheme.Typography.label).fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))

            HStack {
                Group {
                    if showPassword {
                        TextField(locManager.t("auth.password_placeholder"), text: $password)
                    } else {
                        SecureField(locManager.t("auth.password_placeholder"), text: $password)
                    }
                }
                .font(AppTheme.Typography.body)
                .foregroundColor(.white)

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
            .background(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(AppTheme.Spacing.radiusMd)
        }
    }

    private var termsRow: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Button(action: { agreeToTerms.toggle() }) {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.accent)
            }
            .frame(width: AppTheme.Layout.compactIconButtonSize, height: AppTheme.Layout.compactIconButtonSize, alignment: .top)

            VStack(alignment: .leading, spacing: 4) {
                Text(locManager.t("auth.i_agree_to_the"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 4) {
                        termsLink
                        termsAndText
                        privacyLink
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            termsLink
                            termsAndText
                        }
                        privacyLink
                    }
                }
            }
        }
    }

    private var termsLink: some View {
        Button(action: { activeLegalSheet = .terms }) {
            Text(locManager.t("auth.terms"))
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.accent)
        }
    }

    private var termsAndText: some View {
        Text(locManager.t("auth.and"))
            .font(AppTheme.Typography.caption)
            .foregroundColor(.white.opacity(0.5))
    }

    private var privacyLink: some View {
        Button(action: { activeLegalSheet = .privacy }) {
            Text(locManager.t("auth.privacy_policy"))
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.accent)
                .lineLimit(2)
        }
    }
}
