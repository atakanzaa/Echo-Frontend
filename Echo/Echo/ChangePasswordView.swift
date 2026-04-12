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
                HStack {
                    Button(action: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "settings")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    Spacer()
                    Text(locManager.t("settings.change_password"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()
                    Color.clear.frame(width: 16, height: 16)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)

                ScrollView(showsIndicators: false) {
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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.Gradients.accent)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.Spacing.radiusFull)
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
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 4)
                .background(AppTheme.Colors.surfaceElevated(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
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
