import SwiftUI
import Observation

/// Kullanıcının görünüm tercihi.
nonisolated enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Görünüm tercihini cihazda saklar. Reduce Motion ve Dynamic Type sistemden okunur.
@Observable
final class ThemeManager {
    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: AppPreferenceKey.appearance.rawValue) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: AppPreferenceKey.appearance.rawValue)
        appearance = stored.flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}
