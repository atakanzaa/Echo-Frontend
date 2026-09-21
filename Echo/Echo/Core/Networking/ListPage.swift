import Foundation

/// Cursor sayfalamasının uygulama karşılığı (rules.md §10).
/// `hasMore=false` olduğunda ek sayfa istenmez; cursor opaque kabul edilir.
nonisolated struct ListPage<Element: Sendable>: Sendable {
    let items: [Element]
    let nextCursor: String?
    let hasMore: Bool

    init(items: [Element], nextCursor: String?, hasMore: Bool) {
        self.items = items
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }

    static var empty: ListPage<Element> { ListPage(items: [], nextCursor: nil, hasMore: false) }

    func map<T: Sendable>(_ transform: (Element) -> T) -> ListPage<T> {
        ListPage<T>(items: items.map(transform), nextCursor: nextCursor, hasMore: hasMore)
    }
}

/// Sayfalı listelerin ekran tarafındaki birikimi.
@Observable
@MainActor
final class PaginatedList<Element: Sendable & Identifiable> {
    private(set) var items: [Element] = []
    private(set) var isLoading = false
    private(set) var error: AppError?
    private(set) var hasMore = true
    private var cursor: String?
    private let pageSize: Int
    private let load: (String?, Int) async throws -> ListPage<Element>

    init(pageSize: Int = 20, load: @escaping (String?, Int) async throws -> ListPage<Element>) {
        self.pageSize = pageSize
        self.load = load
    }

    func refresh() async {
        cursor = nil
        hasMore = true
        items = []
        await loadNext()
    }

    func loadNext() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        error = nil
        do {
            let page = try await load(cursor, pageSize)
            items.append(contentsOf: page.items)
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
        } catch {
            self.error = AppError.displayable(error)
        }
        isLoading = false
    }

    /// Sunucudan silinen öğeyi listeden düşürür; sayaçlar sunucudan yeniden okunur.
    func remove(id: Element.ID) {
        items.removeAll { $0.id == id }
    }
}
