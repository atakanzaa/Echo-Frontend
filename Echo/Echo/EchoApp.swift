//
//  EchoApp.swift
//  Echo
//
//  Created by yeniMac on 18.02.2026.
//

import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct EchoApp: App {

    @StateObject private var appState = AppState.shared
    @StateObject private var locManager = LocalizationManager.shared
    @StateObject private var notificationVM = NotificationViewModel.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppConstants.Storage.privateMode) private var privateMode = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if appState.isAuthenticated {
                        ContentView()
                    } else {
                        AuthenticationView()
                    }
                }

                if appState.isRestoringSession {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text(locManager.t("app.restoring_session"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(16)
                    }
                    .transition(.opacity)
                }

                if shouldShowPrivacyCover {
                    PrivacyCoverView()
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .environmentObject(appState)
            .environmentObject(locManager)
            .environmentObject(notificationVM)
            .privacySensitive(appState.isAuthenticated || privateMode)
            .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
            .animation(.easeInOut(duration: 0.2), value: appState.isRestoringSession)
            .animation(.easeInOut(duration: 0.12), value: shouldShowPrivacyCover)
            .onOpenURL { url in
#if canImport(GoogleSignIn)
                GIDSignIn.sharedInstance.handle(url)
#endif
            }
        }
    }

    private var shouldShowPrivacyCover: Bool {
        scenePhase != .active
    }
}

private struct PrivacyCoverView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background(.dark)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.Gradients.accent)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )

                Text(AppConstants.Brand.companyDisplayName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}
