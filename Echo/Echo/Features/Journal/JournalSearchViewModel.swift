import Foundation
import Observation

@Observable
@MainActor
final class JournalSearchViewModel {
    var query = ""
    private(set) var results: [JournalEntry] = []
    private(set) var isLoading = false
    private(set) var hasMore = false
    private(set) var error: AppError?

    @ObservationIgnored private let journal: any JournalServicing
    @ObservationIgnored private var cursor: String?
    @ObservationIgnored private var activeQuery = ""

    init(journal: any JournalServicing) {
        self.journal = journal
    }

    var normalizedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isTooShort: Bool { !normalizedQuery.isEmpty && normalizedQuery.count < 2 }
    var isTooLong: Bool { normalizedQuery.count > 100 }

    func queryChanged() async {
        let requestedQuery = normalizedQuery
        results = []
        cursor = nil
        hasMore = false
        error = nil
        activeQuery = requestedQuery
        guard (2...100).contains(requestedQuery.count) else { return }
        do {
            try await Task.sleep(for: .milliseconds(350))
            try Task.checkCancellation()
            await loadNext(expectedQuery: requestedQuery)
        } catch {
            // Yeni tuş vuruşu önceki debounce görevini iptal eder.
        }
    }

    func loadNext() async {
        await loadNext(expectedQuery: activeQuery)
    }

    private func loadNext(expectedQuery: String) async {
        guard expectedQuery == normalizedQuery,
              (2...100).contains(expectedQuery.count),
              !isLoading,
              results.isEmpty || hasMore else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let page = try await journal.search(query: expectedQuery, cursor: cursor, size: 20)
            guard expectedQuery == normalizedQuery else { return }
            results.append(contentsOf: page.items)
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
        } catch is CancellationError {
            return
        } catch {
            guard expectedQuery == normalizedQuery else { return }
            self.error = AppError.displayable(error)
        }
    }
}
