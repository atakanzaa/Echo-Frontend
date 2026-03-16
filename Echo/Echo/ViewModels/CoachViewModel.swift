import Foundation
import Combine

@MainActor
final class CoachViewModel: ObservableObject {

    @Published var sessions:     [APICoachSession] = []
    @Published var messages:     [APICoachMessage] = []
    @Published var inputText     = ""
    @Published var isLoading     = false
    @Published var isSending     = false
    @Published var errorMessage: String?

    private var currentSessionId: String?

    // MARK: — Session Management

    func loadOrCreateSession() {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let result: [APICoachSession] = try await APIClient.shared.requestWithAutoRefresh(
                    .getCoachSessions
                )
                sessions = result
                if let active = result.first(where: { $0.isActive }) ?? result.first {
                    currentSessionId = active.id
                    await loadMessages(sessionId: active.id)
                } else {
                    // Yeni oturum oluştur
                    let newSession: APICoachSession = try await APIClient.shared.requestWithAutoRefresh(
                        .createCoachSession
                    )
                    currentSessionId = newSession.id
                    sessions.insert(newSession, at: 0)
                }
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func loadMessages(sessionId: String) async {
        do {
            let result: [APICoachMessage] = try await APIClient.shared.requestWithAutoRefresh(
                .getCoachMessages(sessionId: sessionId)
            )
            messages = result
        } catch {
            // sessizce geç
        }
    }

    // MARK: — Journal Kontekstli Oturum

    /// Journal hakkinda konusmak icin yeni coach oturumu baslatir
    func startSessionWithJournal(journalEntryId: String) {
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let newSession: APICoachSession = try await APIClient.shared.requestWithAutoRefresh(
                    .createCoachSessionWithJournal(journalEntryId: journalEntryId)
                )
                currentSessionId = newSession.id
                sessions.insert(newSession, at: 0)
                await loadMessages(sessionId: newSession.id)
                isLoading = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    // MARK: — Send Message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let sessionId = currentSessionId else { return }
        inputText = ""
        isSending = true

        // Optimistic: kullanıcı mesajını hemen ekle
        let tempUserMsg = APICoachMessage(
            id:        UUID().uuidString,
            role:      "user",
            content:   text,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(tempUserMsg)

        Task {
            do {
                // Backend: kullanıcı mesajını gönder, AI yanıtını al
                // Endpoint kullanıcı + AI mesajını [APICoachMessage] olarak döndürür
                let response: [APICoachMessage] = try await APIClient.shared.requestWithAutoRefresh(
                    .sendCoachMessage(sessionId: sessionId, body: SendCoachMessageBody(content: text, role: "user"))
                )
                // Temp user mesajını kaldır, backend yanıtını ekle
                messages.removeLast()
                messages.append(contentsOf: response)
                isSending = false
            } catch {
                // Temp mesajı kaldır
                if !messages.isEmpty { messages.removeLast() }
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isSending    = false
            }
        }
    }
}

extension APICoachMessage {
    var isUser: Bool { role == "user" }

    var formattedTime: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else { return "" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
