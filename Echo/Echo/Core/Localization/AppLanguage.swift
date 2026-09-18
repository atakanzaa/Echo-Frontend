import Foundation
import Observation
import os

/// Uygulama dili. `Accept-Language` bu değerden gönderilir; sunucu metinleri bu dile göre gelir (rules.md §11).
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case turkish = "tr"
    case english = "en"

    var id: String { rawValue }

    /// Cihaz diline en yakın desteklenen dil; desteklenmiyorsa İngilizce.
    static var deviceDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("tr") ? .turkish : .english
    }
}

/// Dili hem arayüze (@Observable) hem ağ katmanına (kilitli kutu) taşır.
@Observable
@MainActor
final class AppLanguageStore {
    private static let defaultsKey = "echo.preferences.language"

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            defaults.set(language.rawValue, forKey: Self.defaultsKey)
            box.set(language)
        }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored nonisolated private let box: LanguageBox

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.defaultsKey).flatMap(AppLanguage.init(rawValue:))
        let resolved = stored ?? .deviceDefault
        language = resolved
        box = LanguageBox(resolved)
    }

    /// Ağ katmanının her istekte okuduğu kapanış.
    nonisolated var headerProvider: @Sendable () -> String? {
        let box = self.box
        return { box.get().rawValue }
    }
}

/// Dil değerini iş parçacıkları arasında güvenle taşır.
nonisolated final class LanguageBox: Sendable {
    private let storage: OSAllocatedUnfairLock<AppLanguage>

    init(_ language: AppLanguage) {
        storage = OSAllocatedUnfairLock(initialState: language)
    }

    func get() -> AppLanguage { storage.withLock { $0 } }
    func set(_ language: AppLanguage) { storage.withLock { $0 = language } }
}
