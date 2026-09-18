import SwiftUI
import UserNotifications

/// Altı adımlı onboarding (plan §4.3). Backend alanı olmayan kişiselleştirme soruları sorulmaz;
/// tamamlanma bilgisi cihazda kullanıcı kimliği başına saklanır.
struct OnboardingFlowView: View {
    let userID: String
    let onFinished: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var step = 0
    @State private var kvkkConsent = false
    @State private var aiTrainingConsent = false
    @State private var reminderHour = 20
    @State private var error: AppError?
    @State private var isWorking = false

    private var totalSteps: Int { 6 }

    var body: some View {
        VStack(spacing: AppTheme.space.lg) {
            EchoOnboardingProgress(step: step + 1, total: totalSteps, onBack: step > 0 ? { step -= 1 } : nil)
                .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            if let error, let message = error.serverMessage ?? error.messageKey.map({ String(localized: String.LocalizationValue($0)) }) {

                EchoBanner(kind: .danger, title: message)
                    .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            }
            ScrollView {
                content
                    .frame(maxWidth: AppTheme.layout.onboardingContentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            }
            footer
                .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
                .padding(.bottom, AppTheme.space.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
        .task { await loadConsent() }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case 0:
            stepBody(title: "onboarding.welcomeTitle", message: "onboarding.welcomeBody", systemImage: "sparkles")
        case 1:
            consentStep
        case 2:
            reminderStep
        case 3:
            stepBody(title: "onboarding.notificationsTitle", message: "onboarding.notificationsBody", systemImage: "bell")
        case 4:
            stepBody(title: "onboarding.microphoneTitle", message: "onboarding.microphoneBody", systemImage: "mic")
        default:
            stepBody(title: "onboarding.readyTitle", message: "onboarding.readyBody", systemImage: "checkmark.seal")
        }
    }

    private func stepBody(title: LocalizedStringKey, message: LocalizedStringKey, systemImage: String) -> some View {
        VStack(spacing: AppTheme.space.sm) {
            EchoRippleMark(systemImage: systemImage)
            Text(title).echoTextStyle(.title2).foregroundStyle(AppTheme.color.content.primary)
            Text(message)
                .echoTextStyle(.callout)
                .foregroundStyle(AppTheme.color.content.secondary)
                .multilineTextAlignment(.center)
        }
    }

    /// Rıza metinleri ve zorunluluk bilgisi `app/config`'ten gelir.
    private var consentStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.sm) {
            Text("onboarding.consentTitle").echoTextStyle(.title2).foregroundStyle(AppTheme.color.content.primary)
            if let disclaimer = environment.remoteConfig.config?.aiDisclaimer(for: environment.language.language) {

                Text(disclaimer)
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
            }
            Toggle(isOn: $kvkkConsent) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("onboarding.kvkk").echoTextStyle(.body)
                    if environment.remoteConfig.config?.requiresKVKKConsent == true {

                        Text("consent.required").echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.tertiary)
                    }
                }
            }
            Toggle(isOn: $aiTrainingConsent) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("onboarding.aiTraining").echoTextStyle(.body)
                    if environment.remoteConfig.config?.requiresAITrainingConsent == true {

                        Text("consent.required").echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.tertiary)
                    }
                }
            }
            if let crisis = environment.remoteConfig.config?.crisis {

                EchoBanner(kind: .info,
                           title: crisis.name(for: environment.language.language),
                           message: crisis.phoneNumber + " · " + crisis.availability(for: environment.language.language))
            }
        }
        .tint(AppTheme.color.accent.primary)
    }

    private var reminderStep: some View {
        VStack(spacing: AppTheme.space.sm) {
            EchoRippleMark(systemImage: "clock")
            Text("onboarding.reminderTitle").echoTextStyle(.title2).foregroundStyle(AppTheme.color.content.primary)
            Text("onboarding.reminderBody")
                .echoTextStyle(.callout)
                .foregroundStyle(AppTheme.color.content.secondary)
                .multilineTextAlignment(.center)
            Picker("onboarding.reminderTitle", selection: $reminderHour) {
                ForEach(0..<24, id: \.self) { hour in

                    Text(verbatim: String(format: "%02d:00", hour)).tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
        }
    }

    private var footer: some View {
        VStack(spacing: AppTheme.space.xxs) {
            EchoButton(step == totalSteps - 1 ? "onboarding.finish" : "common.continue",
                       size: .lg, fullWidth: true, isLoading: isWorking) { advance() }
                .disabled(!canAdvance)
            if step == 3 || step == 4 {

                EchoButton("onboarding.skip", variant: .ghost, size: .sm) { step += 1 }
            }
        }
    }

    private var canAdvance: Bool {
        guard step == 1, let config = environment.remoteConfig.config else { return true }
        if config.requiresKVKKConsent && !kvkkConsent { return false }
        if config.requiresAITrainingConsent && !aiTrainingConsent { return false }
        return true
    }

    private func loadConsent() async {
        guard let consent = try? await environment.user.consent() else { return }
        kvkkConsent = consent.kvkkExplicitConsent
        aiTrainingConsent = consent.aiTrainingConsent
    }

    private func advance() {
        Task {
            isWorking = true
            error = nil
            do {
                switch step {
                case 1:
                    _ = try await environment.user.updateConsent(aiTraining: aiTrainingConsent,
                                                                 kvkk: kvkkConsent,
                                                                 communityTerms: nil)
                case 2:
                    var preferences = try await environment.notifications.preferences()
                    preferences.dailyRemindersEnabled = true
                    preferences.preferredLocalHour = reminderHour
                    preferences.timezone = TimeZone.current.identifier
                    _ = try await environment.notifications.updatePreferences(preferences)
                case 3:
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                case 4:
                    _ = await AudioPermissions.requestMicrophone()
                    _ = await AudioPermissions.requestSpeechRecognition()
                default:
                    break
                }
                if step == totalSteps - 1 {

                    OnboardingState.markCompleted(userID: userID)
                    onFinished()
                } else {
                    step += 1
                }
            } catch {
                self.error = AppError.from(error)
            }
            isWorking = false
        }
    }
}

/// Backend'de `onboarding_completed` alanı yok; tamamlanma cihazda kullanıcı kimliği başına saklanır.
nonisolated enum OnboardingState {
    private static func key(_ userID: String) -> String { "echo.onboarding.completed." + userID }

    static func isCompleted(userID: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(userID))
    }

    static func markCompleted(userID: String, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(userID))
    }
}
