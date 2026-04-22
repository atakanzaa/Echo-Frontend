import SwiftUI

struct ChangePasswordView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = AuthViewModel()
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var successMessage: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("settings.change_password"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "settings")
                    }
                )

                KeyboardAwareFormScroll {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        field(title: locManager.t("auth.current_password"), placeholder: locManager.t("auth.current_password_placeholder"), text: $currentPassword)
                        field(title: locManager.t("auth.new_password"), placeholder: locManager.t("auth.new_password_placeholder"), text: $newPassword)
                        field(title: locManager.t("auth.confirm_password"), placeholder: locManager.t("auth.confirm_password_placeholder"), text: $confirmPassword)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let successMessage {
                            Text(successMessage)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.moodVeryPositive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: submit) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(locManager.t("auth.change_password_action"))
                                        .font(AppTheme.Typography.bodyEm)
                                }
                            }
                            .echoPrimaryButton(colorScheme, enabled: !viewModel.isLoading)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
        }
    }

    private func field(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            SecureField(placeholder, text: text)
                .echoInputField(colorScheme)
        }
    }

    private func submit() {
        Task {
            successMessage = nil
            guard newPassword.count >= 8 else {
                viewModel.errorMessage = locManager.t("auth.password_min_length")
                return
            }
            guard newPassword == confirmPassword else {
                viewModel.errorMessage = locManager.t("auth.password_mismatch")
                return
            }

            let success = await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            if success {
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                successMessage = locManager.t("auth.password_changed_success")
            }
        }
    }
}
