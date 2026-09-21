import SwiftUI

/// Uygulama kökü: açılış → (zorunlu güncelleme) → kimlik doğrulama → onboarding → ana kabuk.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var onboardingCompleted = false

    var body: some View {
        content
            .animation(reduceMotion ? .easeInOut(duration: AppTheme.motion.duration.fast) : AppTheme.motion.standard,
                       value: environment.session.state)
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { environment.appLock.lock() }
            }
    }

    @ViewBuilder private var content: some View {
        if environment.remoteConfig.requiresUpdate {

            UpdateRequiredView(storeURL: environment.remoteConfig.config?.release.storeURL)
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
}
