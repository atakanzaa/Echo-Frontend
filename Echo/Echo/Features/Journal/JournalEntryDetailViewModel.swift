import Foundation
import Observation

@Observable
@MainActor
final class JournalEntryDetailViewModel {
    private(set) var entry: JournalEntry?
    private(set) var progress: OperationProgress?
    private(set) var isLoading = false
    private(set) var isDeleting = false
    private(set) var isStartingCoach = false
    private(set) var goalSuggestions: [GoalSuggestion] = []
    private(set) var workingSuggestionID: String?
    private(set) var error: AppError?

    let entryID: String

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private let coach: any CoachServicing
    @ObservationIgnored private let goals: any GoalServicing
    @ObservationIgnored private var coachIdempotencyKey: String?
    @ObservationIgnored private var createdCoachSessionID: String?

    init(entryID: String, journal: any JournalServicing, coach: any CoachServicing, goals: any GoalServicing) {
        self.entryID = entryID
        self.journal = journal
        self.coach = coach
        self.goals = goals
    }

    func start() async {
        await load()
        guard entry != nil else { return }
        await loadGoalSuggestions()
        await pollUntilTerminal()
    }

    func reload() async {
        await load()
    }

    func delete() async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        error = nil
        defer { isDeleting = false }
        do {
            try await journal.delete(id: entryID)
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    /// Tek kullanıcı niyeti yeniden denenirse aynı idempotency anahtarı korunur.
    func createCoachSession() async -> String? {
        guard !isStartingCoach else { return nil }
        if let createdCoachSessionID { return createdCoachSessionID }
        isStartingCoach = true
        error = nil
        defer { isStartingCoach = false }
        let key = coachIdempotencyKey ?? UUID().uuidString
        coachIdempotencyKey = key
        do {
            let session = try await coach.createSession(journalEntryID: entryID, idempotencyKey: key)
            coachIdempotencyKey = nil
            createdCoachSessionID = session.id
            return session.id
        } catch {
            let appError = AppError.from(error)
            if !appError.isRetryable {
                if case .authenticationRequired = appError { /* Oturum yenilendiğinde aynı niyet korunur. */ }
                else { coachIdempotencyKey = nil }
            }
            self.error = appError
            return nil
        }
    }

    func acceptSuggestion(id: String) async {
        guard workingSuggestionID == nil else { return }
        workingSuggestionID = id
        error = nil
        defer { workingSuggestionID = nil }
        do {
            _ = try await goals.acceptSuggestion(id: id)
            goalSuggestions.removeAll { $0.id == id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func rejectSuggestion(id: String) async {
        guard workingSuggestionID == nil else { return }
        workingSuggestionID = id
        error = nil
        defer { workingSuggestionID = nil }
        do {
            try await goals.rejectSuggestion(id: id)
            goalSuggestions.removeAll { $0.id == id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    private func load() async {
        isLoading = entry == nil
        error = nil
        defer { isLoading = false }
        do {
            entry = try await journal.entry(id: entryID)
        } catch is CancellationError {
            return
        } catch {
            self.error = AppError.from(error)
        }
    }

    private func loadGoalSuggestions() async {
        guard entry?.analysis != nil else { return }
        do {
            goalSuggestions = try await goals.suggestions(sourceType: "journal", suggestionType: nil,
                                                          journalEntryID: entryID, coachSessionID: nil)
        } catch {
            // Detayın ana içeriği öneri uç noktasından bağımsız kullanılabilir.
        }
    }

    private func pollUntilTerminal() async {
        while !Task.isCancelled {
            guard let entry else { return }
            if entry.status.isSucceeded { return }
            do {
                let state: OperationProgress
                if let operationID = entry.operationID {
                    state = try await journal.operation(id: operationID)
                } else {
                    state = try await journal.status(id: entryID)
                }
                try Task.checkCancellation()
                progress = state
                if state.isTerminal {
                    await load()
                    await loadGoalSuggestions()
                    return
                }
                try await Task.sleep(for: state.pollInterval)
            } catch is CancellationError {
                return
            } catch {
                self.error = AppError.from(error)
                do {
                    try await Task.sleep(for: .seconds(3))
                } catch {
                    return
                }
            }
        }
    }
}
