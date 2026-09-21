import Foundation
import Observation

/// Gönderilmeyi bekleyen günlük kaydı. Anahtar, gövde ve iş kimlikleri cihazda kalıcıdır (rules.md §3).
nonisolated struct PendingJournal: Codable, Sendable, Equatable, Identifiable {
    enum Kind: String, Codable, Sendable {
        case transcript
        case audio
    }

    let id: UUID
    /// Bekleyen iş farklı bir hesap oturumunda yeniden gönderilemez.
    let ownerUserID: String?
    let kind: Kind
    let idempotencyKey: String
    let recordedAt: Date
    let durationSeconds: Int?
    let transcript: String?
    let audioFileName: String?
    var journalEntryID: String?
    var operationID: String?
    var lastErrorCode: String?
}

/// Bekleyen gönderimleri Application Support altında saklar; uygulama kapanıp açılsa da devam eder.
@Observable
@MainActor
final class PendingJournalStore {
    private(set) var items: [PendingJournal] = []

    @ObservationIgnored private let fileURL: URL

    init(directoryName: String = "Pending") {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("pending-journals.json")
        items = (try? JSONDecoder().decode([PendingJournal].self, from: Data(contentsOf: fileURL))) ?? []
    }

    func add(_ item: PendingJournal) {
        items.append(item)
        persist()
    }

    func update(_ item: PendingJournal) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        persist()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func audioURL(for item: PendingJournal) -> URL? {
        guard let name = item.audioFileName else { return nil }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
            .appendingPathComponent(name)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
