import Foundation
import Combine

@MainActor
final class CoachViewModel: ObservableObject {

    // MARK: — Liste State

    @Published var sessions:        [APICoachSession] = []
    @Published var isLoadingSessions = false
    @Published var isLoadingMore    = false
    @Published var hasMorePages     = true
    @Published var listError:       String?

    private var currentPage = 0
    private let pageSize    = 20
    private let sessionsTask = TaskGuard()
    private let loadMoreSessionsTask = TaskGuard()
    private let openSessionTask = TaskGuard()
    private let sendMutationGuard = MutationGuard()
    private let createSessionGuard = MutationGuard()

    // MARK: — Chat State

    @Published var messages:       [APICoachMessage] = []
    @Published var inputText       = ""
    @Published var isLoadingChat   = false
    @Published var isSending       = false
    @Published var chatError:      String?
    @Published var coachSuggestions: [APIGoalSuggestion] = []
    @Published var coachSuccessMessage: String?

    private(set) var activeSessionId: String?

    // MARK: — Session Listesi

    func loadSessions() {
        sessionsTask.run { [weak self] in
            await self?.performLoadSessions()
        }
    }

    func loadMoreSessions() {
        guard hasMorePages, !isLoadingMore, !isLoadingSessions else { return }
        isLoadingMore = true
        let page = currentPage
        loadMoreSessionsTask.run { [weak self] in
            await self?.performLoadMoreSessions(page: page)
        }
    }

    // MARK: — Yeni Session Oluştur

    /// Normal (journal bağlantısız) yeni konuşma başlatır
    func createNewSession() async throws -> APICoachSession {
        guard createSessionGuard.start(id: "new-session") else {
            throw NetworkError.serverError(429, "Session creation already in progress.")
        }
        defer { createSessionGuard.finish(id: "new-session") }
        let newSession: APICoachSession = try await APIClient.shared.requestWithAutoRefresh(.createCoachSession)
        sessions.insert(newSession, at: 0)
        return newSession
    }

    /// Journal bağlantılı yeni konuşma başlatır
    func createSessionWithJournal(journalEntryId: String) async throws -> APICoachSession {
        let key = "journal-\(journalEntryId)"
        guard createSessionGuard.start(id: key) else {
            throw NetworkError.serverError(429, "Session creation already in progress.")
        }
        defer { createSessionGuard.finish(id: key) }
        let newSession: APICoachSession = try await APIClient.shared.requestWithAutoRefresh(
            .createCoachSessionWithJournal(journalEntryId: journalEntryId)
        )
        sessions.insert(newSession, at: 0)
        return newSession
    }

    // MARK: — Chat

    /// Bir session seçilince mesajlarını yükler
    func openSession(id: String) {
        activeSessionId = id
        messages        = []
        isLoadingChat   = true
        chatError       = nil
        openSessionTask.run { [weak self] in
            await self?.performOpenSession(id: id)
        }
        loadCoachSuggestions(sessionId: id)
    }

    func closeSession() {
        // Aktif session'ı soft-close et (arka planda)
        if let sid = activeSessionId {
            Task {
                try? await APIClient.shared.requestWithAutoRefresh(.endCoachSession(sessionId: sid)) as APIVoidResponse
            }
        }
        activeSessionId = nil
        messages        = []
        inputText       = ""
        coachSuggestions = []
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let sessionId = activeSessionId else { return }
        guard sendMutationGuard.start(id: sessionId) else { return }
        inputText = ""
        isSending = true

        // Optimistic: kullanıcı mesajını hemen ekle
        let tempId = UUID().uuidString
        let tempMsg = APICoachMessage(
            id:        tempId,
            role:      "user",
            content:   text,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(tempMsg)

        Task {
            defer {
                sendMutationGuard.finish(id: sessionId)
            }
            do {
                let response: [APICoachMessage] = try await APIClient.shared.requestWithAutoRefresh(
                    .sendCoachMessage(sessionId: sessionId, body: SendCoachMessageBody(content: text, role: .user))
                )
                // Temp mesajı kaldır, backend yanıtını ekle
                messages.removeAll { $0.id == tempId }
                messages.append(contentsOf: response)
                isSending = false
                refreshSessionInList(sessionId: sessionId)
                await self.fetchCoachSuggestions(sessionId: sessionId)
            } catch {
                messages.removeAll { $0.id == tempId }
                chatError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isSending = false
            }
        }
    }


    func acceptSuggestion(_ suggestion: APIGoalSuggestion) {
        guard let sessionId = activeSessionId else { return }
        guard sendMutationGuard.start(id: suggestion.id) else { return }
        Task {
            defer { sendMutationGuard.finish(id: suggestion.id) }
            do {
                let goal: APIGoal = try await APIClient.shared.requestWithAutoRefresh(.acceptGoalSuggestion(id: suggestion.id))
                coachSuggestions.removeAll { $0.id == suggestion.id }
                let key = suggestion.suggestionType == "COMPLETE_GOAL_CONFIRM" ? "goal.success.completed" : "goal.success.added"
                coachSuccessMessage = LocalizationManager.shared.t(key, goal.title)
                await fetchCoachSuggestions(sessionId: sessionId)
            } catch {
                chatError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func rejectSuggestion(_ suggestion: APIGoalSuggestion) {
        guard let sessionId = activeSessionId else { return }
        guard sendMutationGuard.start(id: "reject-\(suggestion.id)") else { return }
        Task {
            defer { sendMutationGuard.finish(id: "reject-\(suggestion.id)") }
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.rejectGoalSuggestion(id: suggestion.id))
                coachSuggestions.removeAll { $0.id == suggestion.id }
                await fetchCoachSuggestions(sessionId: sessionId)
            } catch {
                chatError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func loadCoachSuggestions(sessionId: String) {
        Task { await fetchCoachSuggestions(sessionId: sessionId) }
    }

    // MARK: — Silme

    func deleteSession(id: String) {
        Task {
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .deleteCoachSession(id: id)
                )
                sessions.removeAll { $0.id == id }
            } catch {
                listError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: — Yardımcı

    private func refreshSessionInList(sessionId: String) {
        // Güncellenmiş session'ı listenin başına taşı (son activity göstergesi için)
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        let session = sessions.remove(at: idx)
        sessions.insert(session, at: 0)
    }

    func isInFlight(goalId: String) -> Bool {
        sendMutationGuard.isInFlight(id: goalId)
    }

    func cancelAll() {
        sessionsTask.cancel()
        loadMoreSessionsTask.cancel()
        openSessionTask.cancel()
        sendMutationGuard.reset()
        createSessionGuard.reset()
    }

    func refresh() async {
        await sessionsTask.runAsync { [weak self] in
            await self?.performLoadSessions()
        }
    }

    private func performLoadSessions() async {
        guard !isLoadingSessions else { return }
        currentPage = 0
        hasMorePages = true
        isLoadingSessions = true
        listError = nil
        do {
            let paged: APIPagedResponse<APICoachSession> = try await APIClient.shared.requestWithAutoRefresh(
                .getCoachSessions(page: 0, size: pageSize)
            )
            guard !Task.isCancelled else { return }
            sessions = paged.content
            hasMorePages = !paged.last
            currentPage = 1
            isLoadingSessions = false
        } catch is CancellationError {
            isLoadingSessions = false
        } catch {
            listError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoadingSessions = false
        }
    }

    private func performLoadMoreSessions(page: Int) async {
        do {
            let paged: APIPagedResponse<APICoachSession> = try await APIClient.shared.requestWithAutoRefresh(
                .getCoachSessions(page: page, size: pageSize)
            )
            guard !Task.isCancelled else { return }
            sessions.appendDeduplicating(contentsOf: paged.content)
            hasMorePages = !paged.last
            currentPage = paged.page + 1
            isLoadingMore = false
        } catch is CancellationError {
            isLoadingMore = false
        } catch {
            isLoadingMore = false
        }
    }


    private func fetchCoachSuggestions(sessionId: String) async {
        do {
            let result: [APIGoalSuggestion] = try await APIClient.shared.requestWithAutoRefresh(
                .getGoalSuggestions(sourceType: "COACH", journalEntryId: nil, sessionId: sessionId)
            )
            guard activeSessionId == sessionId else { return }
            coachSuggestions = result
        } catch is CancellationError {
        } catch {
            guard activeSessionId == sessionId else { return }
            chatError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    private func performOpenSession(id: String) async {
        do {
            let result: [APICoachMessage] = try await APIClient.shared.requestWithAutoRefresh(
                .getCoachMessages(sessionId: id)
            )
            guard !Task.isCancelled else { return }
            guard activeSessionId == id else { return }
            messages = result
            isLoadingChat = false
        } catch is CancellationError {
            isLoadingChat = false
        } catch {
            chatError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoadingChat = false
        }
    }
}

enum CoachDateParser {
    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ raw: String) -> Date? {
        if let date = iso8601WithFractional.date(from: raw) { return date }
        return iso8601Standard.date(from: raw)
    }
}

extension APICoachMessage {
    var isUser: Bool { role == "user" }

    var formattedTime: String {
        guard let date = CoachDateParser.parse(createdAt) else { return "" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
