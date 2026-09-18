import SwiftUI

@main
struct EchoApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(themeManager)
                .preferredColorScheme(themeManager.appearance.colorScheme)
                .tint(AppTheme.color.accent.primary)
        }
    }
}
