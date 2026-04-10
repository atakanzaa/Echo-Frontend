import Foundation

@MainActor
final class TaskGuard {
    private var task: Task<Void, Never>?

    func run(_ operation: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task { await operation() }
    }

    func runAsync(_ operation: @escaping @Sendable () async -> Void) async {
        task?.cancel()
        let newTask = Task { await operation() }
        task = newTask
        await newTask.value
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

@MainActor
final class MutationGuard {
    private var inFlightIds: Set<String> = []

    func start(id: String) -> Bool {
        guard !inFlightIds.contains(id) else { return false }
        inFlightIds.insert(id)
        return true
    }

    func finish(id: String) {
        inFlightIds.remove(id)
    }

    func isInFlight(id: String) -> Bool {
        inFlightIds.contains(id)
    }

    func reset() {
        inFlightIds.removeAll()
    }
}
