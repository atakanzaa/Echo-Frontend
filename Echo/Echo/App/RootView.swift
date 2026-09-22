import SwiftUI

/// Uygulama kökü: açılış → (zorunlu güncelleme) → kimlik doğrulama → onboarding → ana kabuk.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var onboardingCompleted = false
    @State private var signInDuringMaintenance = false

    var body: some View {
        content
            .animation(reduceMotion ? .easeInOut(duration: AppTheme.motion.duration.fast) : AppTheme.motion.standard,
                       value: environment.session.state)
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { environment.appLock.lock() }
                // Bakım ve duyurular uygulamaya her dönüşte sunucudan yeniden okunur.
                if phase == .active, environment.session.state != .restoring {

                    Task {
                        await environment.remoteConfig.load()
                        if let userID = environment.session.state.user?.id { await environment.push.refresh(userID: userID) }
                    }
                }
            }
            .task(id: environment.session.state.user?.id) {
                if let userID = environment.session.state.user?.id { await environment.push.refresh(userID: userID) }
            }
    }

    @ViewBuilder private var content: some View {
        if environment.remoteConfig.requiresUpdate {

            UpdateRequiredView(storeURL: environment.remoteConfig.config?.release.storeURL)
        } else if let message = maintenanceMessage {
            MaintenanceView(message: message, allowsSignIn: environment.session.state == .signedOut) {
                signInDuringMaintenance = true
            }
        } else {
            switch environment.session.state {
            case .restoring:
                LaunchView()
            case .signedOut:
                AuthFlowView()
            case .signedIn(let user):
                if onboardingCompleted || OnboardingState.isCompleted(userID: user.id) {

                    if environment.appLock.isEnabled, !environment.appLock.isUnlocked {
                        AppLockView()
                    } else {
                        MainTabView()
                    }
                } else {
                    OnboardingFlowView(userID: user.id) { onboardingCompleted = true }
                }
            }
        }
    }

    /// Bakımda yönetici etkilenmez; oturumu kapalı biri yönetici olabileceği için giriş formu açılabilir.
    private var maintenanceMessage: String? {
        guard let message = environment.remoteConfig.maintenanceMessage else { return nil }
        switch environment.session.state {
        case .signedIn(let user) where user.isAdmin: return nil
        case .signedOut where signInDuringMaintenance: return nil
        default: return message
        }
    }
}
