import Foundation
import Observation

nonisolated enum JournalSubmissionOutcome: Sendable {
    case accepted(JournalEntry)
    /// İsteğin sonucu belirsiz veya geçici olarak başarısız. Aynı kimlik ve aynı gövdeyle yeniden denenir.
    case pending(id: UUID, error: AppError)
    /// Sunucu isteği kalıcı olarak reddetti; yeni kullanıcı niyeti yeni bir anahtar alabilir.
    case rejected(AppError)
}

/// Günlük gönderimi ve iş takibi (rules.md §3–§5).
/// Anahtar kullanıcı niyeti başına bir kez üretilir; timeout başarısızlık değildir, aynı anahtarla tekrar denenir.
@Observable
@MainActor
final class JournalSubmissionStore {
    private(set) var isSubmitting = false
    private(set) var lastError: AppError?
    /// Ekranların izlediği iş durumları: journal id → sunucunun bildirdiği durum.
    private(set) var progress: [String: OperationProgress] = [:]

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private let pending: PendingJournalStore
    @ObservationIgnored private var pollTasks: [String: Task<Void, Never>] = [:]

    init(journal: any JournalServicing, pending: PendingJournalStore) {
        self.journal = journal
        self.pending = pending
    }

    /// Yazılı veya cihazda metne çevrilmiş kayıt. `durationSeconds` yalnız sesli kayıtta gönderilir.
    @discardableResult
    func submitTranscript(_ transcript: String,
                          recordedAt: Date,
                          durationSeconds: Int?,
                          ownerUserID: String,
                          resuming submissionID: UUID? = nil) async -> JournalSubmissionOutcome {
        let existing = reusableItem(id: submissionID, ownerUserID: ownerUserID)
        let item = existing ?? PendingJournal(
            id: UUID(), ownerUserID: ownerUserID, kind: .transcript, idempotencyKey: UUID().uuidString,
            recordedAt: recordedAt, durationSeconds: durationSeconds,
            transcript: transcript, audioFileName: nil,
            journalEntryID: nil, operationID: nil, lastErrorCode: nil)
        if existing == nil { pending.add(item) }
        return await send(item)
    }

    /// Ses dosyası gönderimi; dosya gönderim tamamlanana kadar cihazda kalır.
    @discardableResult
    func submitAudio(fileURL: URL,
                     recordedAt: Date,
                     durationSeconds: Int,
                     ownerUserID: String,
                     resuming submissionID: UUID? = nil) async -> JournalSubmissionOutcome {
        let existing = reusableItem(id: submissionID, ownerUserID: ownerUserID)
        let item = existing ?? PendingJournal(
            id: UUID(), ownerUserID: ownerUserID, kind: .audio, idempotencyKey: UUID().uuidString,
            recordedAt: recordedAt, durationSeconds: durationSeconds,
            transcript: nil, audioFileName: fileURL.lastPathComponent,
            journalEntryID: nil, operationID: nil, lastErrorCode: nil)
        if existing == nil { pending.add(item) }
        return await send(item)
    }

    /// Uygulama yeniden açıldığında yarım kalan gönderimleri aynı anahtarla sürdürür.
    func resumePending(for userID: String) async {
        for item in pending.items where item.ownerUserID == userID {

            if let journalID = item.journalEntryID {

                track(journalID: journalID, operationID: item.operationID)
            } else {
                _ = await send(item)
            }
        }
    }

    private func reusableItem(id: UUID?, ownerUserID: String) -> PendingJournal? {
        guard let id else { return nil }
        return pending.items.first {
            $0.id == id && $0.ownerUserID == ownerUserID && $0.journalEntryID == nil
        }
    }

    private func send(_ item: PendingJournal) async -> JournalSubmissionOutcome {
        isSubmitting = true
        lastError = nil
        defer { isSubmitting = false }
        do {
            let entry: JournalEntry
            switch item.kind {
            case .transcript:
                entry = try await journal.createFromTranscript(transcript: item.transcript ?? "",
                                                               recordedAt: item.recordedAt,
                                                               durationSeconds: item.durationSeconds,
                                                               idempotencyKey: item.idempotencyKey)
            case .audio:
                guard let url = pending.audioURL(for: item) else {
                    pending.remove(id: item.id)
                    let error = AppError.unexpectedResponse(status: nil)
                    lastError = error
                    return .rejected(error)
                }
                entry = try await journal.createFromAudio(fileURL: url,
                                                          recordedAt: item.recordedAt,
                                                          durationSeconds: item.durationSeconds ?? 0,
                                                          idempotencyKey: item.idempotencyKey)
            }
            var updated = item
            updated.journalEntryID = entry.id
            updated.operationID = entry.operationID
            pending.update(updated)
            track(journalID: entry.id, operationID: entry.operationID)
            return .accepted(entry)
        } catch {
            let appError = AppError.from(error)
            lastError = appError
            if shouldKeepPending(appError) {

                var updated = item
                updated.lastErrorCode = appError.problem?.code
                pending.update(updated)
                return .pending(id: item.id, error: appError)
            }
            // Doğrulama/kota gibi kalıcı reddetmeler açılışta otomatik olarak yeniden gönderilmez.
            pending.remove(id: item.id)
            return .rejected(appError)
        }
    }

    private func shouldKeepPending(_ error: AppError) -> Bool {
        switch error {
        case .network, .authenticationRequired:
            return true
        case .problem(let problem):
            return problem.retryable || problem.status == 429 || problem.status >= 500
        case .unexpectedResponse(let status):
            // Gövdesiz bir 5xx veya transport sonrası decode sorunu kabul sonucunu belirsiz bırakır.
            return status == nil || (status.map { $0 >= 500 } ?? false)
        }
    }

    /// `poll_after_ms` aralığıyla tek döngü; terminal durumda durur, ekrandan çıkınca iptal edilir.
    func track(journalID: String, operationID: String?) {
        guard pollTasks[journalID] == nil else { return }
        pollTasks[journalID] = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {

                do {
                    let state: OperationProgress
                    if let operationID {
                        state = try await journal.operation(id: operationID)
                    } else {
                        state = try await journal.status(id: journalID)
                    }
                    progress[journalID] = state
                    if state.isTerminal {

                        finish(journalID: journalID)
                        return
                    }
                    try await Task.sleep(for: state.pollInterval)
                } catch {
                    // Geçici hata: döngü bir sonraki denemede devam eder; iş sunucuda sürüyor.
                    try? await Task.sleep(for: .seconds(3))
                }
            }
        }
    }

    func stopTracking(journalID: String) {
        pollTasks[journalID]?.cancel()
        pollTasks[journalID] = nil
    }

    /// İş bittiğinde bekleyen kayıt ve ses dosyası temizlenir.
    private func finish(journalID: String) {
        pollTasks[journalID]?.cancel()
        pollTasks[journalID] = nil
        guard let item = pending.items.first(where: { $0.journalEntryID == journalID }) else { return }
        if let url = pending.audioURL(for: item) { try? FileManager.default.removeItem(at: url) }
        pending.remove(id: item.id)
    }
}
