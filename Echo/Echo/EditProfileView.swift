import SwiftUI
import Combine

struct EditProfileView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = EditProfileViewModel()

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    Spacer()
                    Text(locManager.t("profile.edit_profile"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()
                    // Save button
                    Button(action: {
                        viewModel.save {
                            selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                        }
                    }) {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        } else {
                            Text(locManager.t("common.save"))
                                .font(AppTheme.Typography.bodyEm)
                                .foregroundColor(viewModel.hasChanges ? AppTheme.Colors.accent : AppTheme.Colors.textDisabled(colorScheme))
                        }
                    }
                    .disabled(!viewModel.hasChanges || viewModel.isSaving)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Avatar
                            VStack(spacing: AppTheme.Spacing.md) {
                                UserInitialsView(displayName: viewModel.displayName, size: 96)
                            }
                            .padding(.top, AppTheme.Spacing.md)

                            // Display Name field
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text(locManager.t("profile.display_name").uppercased())
                                    .font(AppTheme.Typography.label).fontWeight(.bold)
                                    .tracking(0.6)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

                                TextField(locManager.t("profile.display_name_placeholder"), text: $viewModel.displayName)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.surfaceElevated(colorScheme))
                                    .cornerRadius(AppTheme.Spacing.radiusMd)
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            // Email (read-only)
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text(locManager.t("profile.email_label").uppercased())
                                    .font(AppTheme.Typography.label).fontWeight(.bold)
                                    .tracking(0.6)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

                                HStack {
                                    Text(viewModel.email)
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.Colors.textDisabled(colorScheme))
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.surface(colorScheme))
                                .cornerRadius(AppTheme.Spacing.radiusMd)
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            // Error message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.destructive)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                            }

                            Spacer().frame(height: AppTheme.Spacing.xxl)
                        }
                    }
                }
            }
        }
        .onAppear { viewModel.loadUser() }
    }
}

// MARK: - ViewModel

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private var originalDisplayName = ""

    var hasChanges: Bool {
        displayName != originalDisplayName && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func loadUser() {
        guard email.isEmpty else { return }
        isLoading = true
        Task {
            do {
                let user: APIUser = try await APIClient.shared.requestWithAutoRefresh(.me)
                displayName = user.displayName ?? ""
                originalDisplayName = displayName
                email = user.email
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func save(onSuccess: @escaping () -> Void) {
        guard hasChanges else { return }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                let body = UpdateProfileBody(
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    timezone: nil
                )
                let _: APIUser = try await APIClient.shared.requestWithAutoRefresh(.updateProfile(body))
                originalDisplayName = displayName
                isSaving = false
                onSuccess()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
