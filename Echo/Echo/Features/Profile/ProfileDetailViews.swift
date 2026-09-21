import SwiftUI

struct EditProfileView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var timezone = ""
    @State private var isSaving = false
    @State private var error: AppError?

    var body: some View {
        Form {
            Section("profile.personalInfo") {
                TextField("profile.displayName", text: $displayName)
                TextField("profile.timezone", text: $timezone)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            if let error { Text(JournalPresentation.errorMessage(error)).foregroundStyle(AppTheme.color.feedback.danger) }
            EchoButton("common.save", fullWidth: true, isLoading: isSaving) { Task { await save() } }
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || timezone.isEmpty)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("profile.editTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let user = environment.session.state.user else { return }
            displayName = user.displayName ?? ""
            timezone = user.timezone
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true; error = nil
        defer { isSaving = false }
        do {
            let updated = try await environment.user.updateProfile(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                timezone: timezone, language: nil)
            environment.session.apply(updated)
            dismiss()
        } catch { self.error = AppError.displayable(error) }
    }
}

@Observable
@MainActor
private final class PrivacyConsentViewModel {
    var status: ConsentStatus?
    var isLoading = false
    var error: AppError?
    @ObservationIgnored private let user: any UserServicing
    init(user: any UserServicing) { self.user = user }

    func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do { status = try await user.consent() }
        catch { self.error = AppError.displayable(error) }
    }

    func update(aiTraining: Bool? = nil, kvkk: Bool? = nil) async {
        do { status = try await user.updateConsent(aiTraining: aiTraining, kvkk: kvkk, communityTerms: nil) }
        catch { self.error = AppError.displayable(error) }
    }
}

struct PrivacyConsentView: View {
    @State private var model: PrivacyConsentViewModel
    init(user: any UserServicing) { _model = State(initialValue: PrivacyConsentViewModel(user: user)) }

    var body: some View {
        Form {
            if let error = model.error { Text(JournalPresentation.errorMessage(error)).foregroundStyle(AppTheme.color.feedback.danger) }
            if let status = model.status {
                Section("consent.data") {
                    Toggle("consent.kvkk", isOn: Binding(
                        get: { status.kvkkExplicitConsent },
                        set: { value in Task { await model.update(kvkk: value) } }))
                    Toggle("consent.aiTraining", isOn: Binding(
                        get: { status.aiTrainingConsent },
                        set: { value in Task { await model.update(aiTraining: value) } }))
                }
                if let version = status.privacyPolicyVersion {
                    Section("consent.versions") { LabeledContent("consent.privacyVersion", value: version) }
                }
            } else if model.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("consent.title"))
        .task { await model.load() }
    }
}
