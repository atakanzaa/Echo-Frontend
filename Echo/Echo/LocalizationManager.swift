//
//  LocalizationManager.swift
//  Echo
//

import SwiftUI
import Combine

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let languageKey = "appLanguage"

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: Self.languageKey)
        }
    }

    private init() {
        currentLanguage = UserDefaults.standard.string(forKey: Self.languageKey) ?? "tr"
    }

    func t(_ key: String) -> String {
        if let value = translations[currentLanguage]?[key] {
            return value
        }
        if let value = translations["en"]?[key] {
            return value
        }
        return key
            .split(separator: ".")
            .last
            .map(String.init)?
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
            ?? key
    }

    func t(_ key: String, _ args: CVarArg...) -> String {
        let format = t(key)
        return String(format: format, arguments: args)
    }
}
