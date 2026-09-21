import Foundation
import Observation

@Observable
@MainActor
final class JournalFeedViewModel {
    struct Section: Identifiable {
        let id: JournalMonthGroup
        let entries: [JournalEntry]
    }

    private(set) var entries: [JournalEntry] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var error: AppError?

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private let timeZone: TimeZone
    @ObservationIgnored private var cursor: String?

    init(journal: any JournalServicing, timeZone: TimeZone) {
        self.journal = journal
        self.timeZone = timeZone
    }

    func refresh() async {
        cursor = nil
        hasMore = true
        entries = []
        await loadNext()
    }

    func loadNext() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let page = try await journal.recent(cursor: cursor, size: 20)
            entries.append(contentsOf: page.items)
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    func delete(id: String) async -> Bool {
        error = nil
        do {
            try await journal.delete(id: id)
            // Liste öğesi düşürülür; kullanıcı/sayaç değerleri istemcide hesaplanmaz.
            entries.removeAll { $0.id == id }
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    var groupedEntries: [Section] {
        let groups = Dictionary(grouping: entries) { entry in
            if let day = entry.entryDay {
                return JournalMonthGroup(year: day.year, month: day.month)
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let components = calendar.dateComponents([.year, .month], from: entry.recordedAt)
            return JournalMonthGroup(year: components.year ?? 0, month: components.month ?? 1)
        }
        return groups.keys.sorted {
            ($0.year, $0.month) > ($1.year, $1.month)
        }.map { Section(id: $0, entries: groups[$0] ?? []) }
    }
}
