import SwiftUI

/// Uygulama kökü: açılış → (zorunlu güncelleme) → kimlik doğrulama → onboarding → ana kabuk.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var onboardingCompleted = false

    var body: some View {
        content
            .animation(AppTheme.motion.standard, value: environment.session.state)
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

                    MainTabView()
                } else {
                    OnboardingFlowView(userID: user.id) { onboardingCompleted = true }
                }
            }
        }
    }
}
