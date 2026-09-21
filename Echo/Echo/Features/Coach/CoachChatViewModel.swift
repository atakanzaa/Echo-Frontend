import Foundation
import Observation

nonisolated struct CoachChatItem: Identifiable, Sendable {
    let id: String
    let role: EchoChatRole
    let text: String
    let createdAt: Date
    let isLocal: Bool
}

@Observable
@MainActor
final class CoachChatViewModel {
    var draft = ""
    private(set) var sessionID: String?
    private(set) var items: [CoachChatItem] = []
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var isThinking = false
    private(set) var hasMore = false
    private(set) var error: AppError?

    @ObservationIgnored private let coach: any CoachServicing
    @ObservationIgnored private var cursor: String?
    @ObservationIgnored private var sessionKey = UUID().uuidString
    @ObservationIgnored private var pendingText: String?
    @ObservationIgnored private var pendingMessageKey: String?

    init(sessionID: String?, coach: any CoachServicing) {
        self.sessionID = sessionID
        self.coach = coach
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && !isThinking
    }

    var canRetry: Bool { sessionID == nil || pendingText != nil }

    func start() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if sessionID == nil {
                sessionID = try await coach.createSession(journalEntryID: nil, idempotencyKey: sessionKey).id
            }
            try await loadMessages(reset: true)
        } catch {
            self.error = AppError.from(error)
        }
    }

    func loadOlder() async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await loadMessages(reset: false)
        } catch {
            self.error = AppError.from(error)
        }
    }

    func send() async {
        guard let sessionID, !isSending, !isThinking else { return }
        let text = pendingText ?? draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let key = pendingMessageKey ?? UUID().uuidString
        pendingText = text
        pendingMessageKey = key
        isSending = true
        error = nil
        if !items.contains(where: { $0.id == "local-\(key)" }) {
            items.append(CoachChatItem(id: "local-\(key)", role: .user, text: text, createdAt: Date(), isLocal: true))
        }
        draft = ""
        do {
            let operation = try await coach.sendMessage(sessionID: sessionID, content: text, idempotencyKey: key)
            pendingText = nil
            pendingMessageKey = nil
            isSending = false
            isThinking = !operation.isTerminal
            if operation.isTerminal {
                await operationFinished(operation)
            } else {
                await poll(operation)
            }
        } catch {
            isSending = false
            let appError = AppError.from(error)
            let authenticationRequired: Bool
            if case .authenticationRequired = appError { authenticationRequired = true }
            else { authenticationRequired = false }
            if !appError.isRetryable, !authenticationRequired {
                draft = text
                pendingText = nil
                pendingMessageKey = nil
                items.removeAll { $0.id == "local-\(key)" }
            }
            self.error = appError
        }
    }

    func endSession() async -> Bool {
        guard let sessionID else { return false }
        do {
            try await coach.endSession(id: sessionID)
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    func deleteSession() async -> Bool {
        guard let sessionID else { return false }
        do {
            try await coach.deleteSession(id: sessionID)
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    private func loadMessages(reset: Bool) async throws {
        guard let sessionID else { return }
        let page = try await coach.messages(sessionID: sessionID, cursor: reset ? nil : cursor, size: 50)
        let mapped = page.items.map {
            CoachChatItem(id: $0.id, role: chatRole($0.role), text: $0.content,
                          createdAt: $0.createdAt, isLocal: false)
        }
        if reset {
            items = mapped
        } else {
            items.append(contentsOf: mapped)
        }
        items = Array(Dictionary(grouping: items, by: \.id).compactMap { $0.value.first })
            .sorted { $0.createdAt < $1.createdAt }
        cursor = page.nextCursor
        hasMore = page.hasMore && page.nextCursor != nil
    }

    private func poll(_ initial: OperationProgress) async {
        var state = initial
        while !Task.isCancelled, !state.isTerminal {
            do {
                try await Task.sleep(for: state.pollInterval)
                state = try await coach.operation(id: state.id)
            } catch is CancellationError {
                isThinking = false
                return
            } catch {
                self.error = AppError.from(error)
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
            }
        }
        guard !Task.isCancelled else { return }
        await operationFinished(state)
    }

    private func operationFinished(_ state: OperationProgress) async {
        isThinking = false
        if state.status.isSucceeded {
            do {
                try await loadMessages(reset: true)
            } catch {
                self.error = AppError.from(error)
            }
        } else {
            error = .unexpectedResponse(status: nil)
        }
    }

    private func chatRole(_ role: CoachMessage.Role) -> EchoChatRole {
        switch role {
        case .user: .user
        case .assistant: .coach
        case .system, .unknown: .system
        }
    }
}
