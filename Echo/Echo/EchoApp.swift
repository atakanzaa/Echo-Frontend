//
//  EchoApp.swift
//  Echo
//
//  Created by yeniMac on 18.02.2026.
//

import SwiftUI

@main
struct EchoApp: App {

    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isAuthenticated {
                    ContentView()
                } else {
                    AuthenticationView()
                }
            }
            .environmentObject(appState)
            .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        }
    }
}
