import Foundation
import Combine

@MainActor
final class TabNavigationManager: ObservableObject {
    private var history: [AppTab] = []
    private var suppressNextRecord = false

    func recordTransition(from oldTab: AppTab, to newTab: AppTab) {
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

    func goBack(from currentTab: AppTab, fallback: AppTab) -> AppTab {
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
