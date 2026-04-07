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
    private let pageSize    = AppConstants.Pagination.defaultPageSize

    // MARK: — Chat State

    @Published var messages:       [APICoachMessage] = []
    @Published var inputText       = ""
    @Published var isLoadingChat   = false
    @Published var isSending       = false
    @Published var chatError:      String?

    private(set) var activeSessionId: String?

    // MARK: — Session Listesi

    func loadSessions() {
        guard !isLoadingSessions else { return }
        currentPage         = 0
        hasMorePages        = true
        isLoadingSessions   = true
        listError           = nil
        Task {
            do {
                let paged: APIPagedResponse<APICoachSession> = try await APIClient.shared.requestWithAutoRefresh(
                    .getCoachSessions(page: 0, size: pageSize)
                )
                sessions        = paged.content
                hasMorePages    = !paged.last
                currentPage     = 1
                isLoadingSessions = false
            } catch {
                listError           = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoadingSessions   = false
            }
        }
    }

    func loadMoreSessions() {
        guard hasMorePages, !isLoadingMore, !isLoadingSessions else { return }
        isLoadingMore = true
        Task {
            do {
                let paged: APIPagedResponse<APICoachSession> = try await APIClient.shared.requestWithAutoRefresh(
                    .getCoachSessions(page: currentPage, size: pageSize)
                )
                sessions.append(contentsOf: paged.content)
                hasMorePages  = !paged.last
                currentPage  += 1
                isLoadingMore = false
            } catch {
                isLoadingMore = false
            }
        }
    }

    // MARK: — Yeni Session Oluştur

    /// Normal (journal bağlantısız) yeni konuşma başlatır
    func createNewSession() async throws -> APICoachSession {
        let newSession: APICoachSession = try await APIClient.shared.requestWithAutoRefresh(.createCoachSession)
        sessions.insert(newSession, at: 0)
        return newSession
    }

    /// Journal bağlantılı yeni konuşma başlatır
    func createSessionWithJournal(journalEntryId: String) async throws -> APICoachSession {
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
        Task {
            do {
                let result: [APICoachMessage] = try await APIClient.shared.requestWithAutoRefresh(
                    .getCoachMessages(sessionId: id)
                )
                messages      = result
                isLoadingChat = false
            } catch {
                chatError     = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoadingChat = false
            }
        }
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
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let sessionId = activeSessionId else { return }
        inputText = ""
        isSending = true

        // Optimistic: kullanıcı mesajını hemen ekle
        let tempId = UUID().uuidString
        let tempMsg = APICoachMessage(
            id:        tempId,
            role:      CoachMessageRole.user.rawValue,
            content:   text,
            createdAt: DateFormatting.iso8601String(from: Date())
        )
        messages.append(tempMsg)

        Task {
            do {
                let response: [APICoachMessage] = try await APIClient.shared.requestWithAutoRefresh(
                    .sendCoachMessage(sessionId: sessionId, body: SendCoachMessageBody(content: text, role: .user))
                )
                // Temp mesajı kaldır, backend yanıtını ekle
                messages.removeAll { $0.id == tempId }
                messages.append(contentsOf: response)
                isSending = false
                // Session listesindeki updatedAt'ı güncelle (sıralama için yenile)
                refreshSessionInList(sessionId: sessionId)
            } catch {
                messages.removeAll { $0.id == tempId }
                chatError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isSending = false
            }
        }
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
}

extension APICoachMessage {
    var isUser: Bool { messageRole == .user }

    var formattedTime: String {
        guard let date = DateFormatting.parseISO8601(createdAt) else { return "" }
        return DateFormatting.shortTime(from: date)
    }
}
