import SwiftUI

/// Ana sekmeler (implementation.md §4.9, §5.0). Merkez kayıt butonu sekme değildir, eylemdir.
nonisolated enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case today
    case journal
    case community
    case profile

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .today: "tabs.today"
        case .journal: "tabs.journal"
        case .community: "tabs.community"
        case .profile: "tabs.profile"
        }
    }

    var icon: String {
        switch self {
        case .today: "sun.horizon"
        case .journal: "book"
        case .community: "bubble.left.and.bubble.right"
        case .profile: "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: "sun.horizon.fill"
        case .journal: "book.fill"
        case .community: "bubble.left.and.bubble.right.fill"
        case .profile: "person.fill"
        }
    }
}
