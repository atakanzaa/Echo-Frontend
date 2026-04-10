import Foundation
import Combine

@MainActor
final class TabNavigationManager: ObservableObject {
    private var history: [String] = []
    private var suppressNextRecord = false

    func recordTransition(from oldTab: String, to newTab: String) {
        guard oldTab != newTab else { return }

        if suppressNextRecord {
            suppressNextRecord = false
            return
        }

        history.append(oldTab)
        if history.count > 64 {
            history.removeFirst(history.count - 64)
        }
    }

    func goBack(from currentTab: String, fallback: String) -> String {
        suppressNextRecord = true

        while let previousTab = history.popLast() {
            if previousTab != currentTab {
                return previousTab
            }
        }

        return fallback
    }

    func reset() {
        history.removeAll()
        suppressNextRecord = false
    }
}
