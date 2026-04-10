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
                            Text("Restoring your session…")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(16)
                    }
                    .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .environmentObject(locManager)
            .environmentObject(notificationVM)
            .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
            .animation(.easeInOut(duration: 0.2), value: appState.isRestoringSession)
            .onOpenURL { url in
#if canImport(GoogleSignIn)
                GIDSignIn.sharedInstance.handle(url)
#endif
            }
        }
    }
}
