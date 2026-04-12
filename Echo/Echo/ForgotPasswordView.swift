import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = AuthViewModel()

    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step: Step = .request

    private enum Step {
        case request
        case reset
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        Text(step == .request ? locManager.t("auth.forgot_password_title") : locManager.t("auth.reset_password_title"))
                            .font(AppTheme.Typography.heading2)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                        Text(step == .request ? locManager.t("auth.forgot_password_sub") : locManager.t("auth.reset_password_sub"))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))

                        inputField(title: locManager.t("auth.email"), placeholder: locManager.t("auth.email_placeholder"), text: $email, keyboard: .emailAddress)

                        if step == .reset {
                            inputField(title: locManager.t("auth.reset_code"), placeholder: locManager.t("auth.reset_code_placeholder"), text: $code)
                            secureField(title: locManager.t("auth.new_password"), placeholder: locManager.t("auth.new_password_placeholder"), text: $newPassword)
                            secureField(title: locManager.t("auth.confirm_password"), placeholder: locManager.t("auth.confirm_password_placeholder"), text: $confirmPassword)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.destructive)
                        }

                        Button(action: primaryAction) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(step == .request ? locManager.t("auth.send_reset_code") : locManager.t("auth.reset_password_action"))
                                        .font(AppTheme.Typography.bodyEm)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.Gradients.accent)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.Spacing.radiusFull)
                        }
                        .disabled(viewModel.isLoading)

                        if step == .reset {
                            Button(action: {
                                step = .request
                                code = ""
                                newPassword = ""
                                confirmPassword = ""
                                viewModel.errorMessage = nil
                            }) {
                                Text(locManager.t("auth.resend_code"))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.accent)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(locManager.t("common.cancel")) { dismiss() }
                }
            }
        }
    }

    private func primaryAction() {
        Task {
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !cleanEmail.isEmpty else { return }

            if step == .request {
                let success = await viewModel.forgotPassword(email: cleanEmail)
                if success {
                    step = .reset
                }
                return
            }

            guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            guard newPassword.count >= 8 else {
                viewModel.errorMessage = locManager.t("auth.password_min_length")
                return
            }
            guard newPassword == confirmPassword else {
                viewModel.errorMessage = locManager.t("auth.password_mismatch")
                return
            }

            let success = await viewModel.resetPassword(email: cleanEmail, code: code.trimmingCharacters(in: .whitespacesAndNewlines), newPassword: newPassword)
            if success {
                dismiss()
            }
        }
    }

    private func inputField(title: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 4)
                .background(AppTheme.Colors.surfaceElevated(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
        }
    }

    private func secureField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            SecureField(placeholder, text: text)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 4)
                .background(AppTheme.Colors.surfaceElevated(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
        }
    }
}
