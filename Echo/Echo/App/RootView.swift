import SwiftUI

/// Uygulama kökü. Faz 7'de açılış (config + oturum) ve kimlik doğrulama akışı buraya bağlanır.
struct RootView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview("Kök") {
    RootView().environment(ThemeManager())
}
