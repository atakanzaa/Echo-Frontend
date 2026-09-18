import Foundation
import EchoAPI
import OpenAPIRuntime
import HTTPTypes

/// Günlük uçları (rules.md §3–§5). Create çağrıları kullanıcı niyeti başına tek `Idempotency-Key` alır.
nonisolated protocol JournalServicing: Sendable {
    func createFromTranscript(transcript: String, recordedAt: Date, durationSeconds: Int?, idempotencyKey: String) async throws -> JournalEntry
    func createFromAudio(fileURL: URL, recordedAt: Date, durationSeconds: Int, idempotencyKey: String) async throws -> JournalEntry
    func entry(id: String) async throws -> JournalEntry
    func status(id: String) async throws -> OperationProgress
    func operation(id: String) async throws -> OperationProgress
    func recent(cursor: String?, size: Int) async throws -> ListPage<JournalEntry>
    func entries(day: LocalDay, cursor: String?, size: Int) async throws -> ListPage<JournalEntry>
    func search(query: String, cursor: String?, size: Int) async throws -> ListPage<JournalEntry>
    func onThisDay() async throws -> [OnThisDayEntry]
    func delete(id: String) async throws
}

nonisolated struct LiveJournalService: JournalServicing {
    let stack: EchoAPIStack

    func createFromTranscript(transcript: String, recordedAt: Date, durationSeconds: Int?, idempotencyKey: String) async throws -> JournalEntry {
        let body = Components.Schemas.CreateJournalFromTranscriptRequest(
            transcript: transcript,
            recordedAt: recordedAt,
            durationSeconds: durationSeconds.map(Int32.init))
        let input = Operations.CreateTranscriptJournalEntry.Input(
            headers: .init(idempotencyKey: idempotencyKey), body: .json(body))
        switch try await stack.client.createTranscriptJournalEntry(input) {
        case .accepted(let accepted):
            return JournalEntry(dto: try accepted.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    /// Ses dosyası tek geçişte gönderilir; ağ hatasında aynı anahtarla yeniden denenir.
    func createFromAudio(fileURL: URL, recordedAt: Date, durationSeconds: Int, idempotencyKey: String) async throws -> JournalEntry {
        let data = try Data(contentsOf: fileURL)
        let payload = Operations.CreateAudioJournalEntry.Input.Body.MultipartFormPayload.AudioPayload(body: HTTPBody(data))
        let body = Operations.CreateAudioJournalEntry.Input.Body.multipartForm(
            [.audio(.init(payload: payload, filename: fileURL.lastPathComponent))])
        let input = Operations.CreateAudioJournalEntry.Input(
            query: .init(recordedAt: recordedAt, durationSeconds: Int32(durationSeconds)),
            headers: .init(idempotencyKey: idempotencyKey),
            body: body)
        switch try await stack.client.createAudioJournalEntry(input) {
        case .accepted(let accepted):
            return JournalEntry(dto: try accepted.body.json)
        case let .`default`(status, response):
            throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func entry(id: String) async throws -> JournalEntry {
        switch try await stack.client.getJournalEntry(.init(path: .init(id: id))) {
        case .ok(let ok): return JournalEntry(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func status(id: String) async throws -> OperationProgress {
        switch try await stack.client.getJournalEntryStatus(.init(path: .init(id: id))) {
        case .ok(let ok): return OperationProgress(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func operation(id: String) async throws -> OperationProgress {
        switch try await stack.client.getOperation(.init(path: .init(id: id))) {
        case .ok(let ok): return OperationProgress(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func recent(cursor: String?, size: Int) async throws -> ListPage<JournalEntry> {
        switch try await stack.client.listRecentJournalEntries(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(JournalEntry.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func entries(day: LocalDay, cursor: String?, size: Int) async throws -> ListPage<JournalEntry> {
        switch try await stack.client.listJournalEntriesByDate(.init(query: .init(date: day.isoString, cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(JournalEntry.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func search(query: String, cursor: String?, size: Int) async throws -> ListPage<JournalEntry> {
        switch try await stack.client.searchJournalEntries(.init(query: .init(query: query, cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(JournalEntry.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func onThisDay() async throws -> [OnThisDayEntry] {
        switch try await stack.client.getOnThisDay(.init()) {
        case .ok(let ok):
            return try ok.body.json.entries.map {
                OnThisDayEntry(id: $0.id, day: LocalDay($0.date), summary: $0.summary,
                               moodLabel: $0.moodLabel, moodScore: $0.moodScore, yearsAgo: Int($0.yearsAgo))
            }
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func delete(id: String) async throws {
        switch try await stack.client.deleteJournalEntry(.init(path: .init(id: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
