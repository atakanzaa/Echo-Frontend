import Foundation
import Combine

@MainActor
final class AdminMonitorViewModel: ObservableObject {
    @Published var summary: AdminSummary?
    @Published var errors: [AdminError] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var hasMore = true
    private let pageSize = AppConstants.Pagination.defaultPageSize

    var canLoadMore: Bool { hasMore }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await loadSummary()
        await loadErrors(reset: true)
    }

    func loadSummary() async {
        do {
            let result: AdminSummary = try await APIClient.shared.requestWithAutoRefresh(.adminSummary)
            summary = result
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func loadErrors(reset: Bool) async {
        if reset {
            currentPage = 0
            hasMore = true
        }
        do {
            let response: APIPagedResponse<AdminError> =
                try await APIClient.shared.requestWithAutoRefresh(.adminErrors(page: currentPage, size: pageSize))
            if reset {
                errors = response.content
            } else {
                errors.append(contentsOf: response.content)
            }
            hasMore = !response.last
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoading, !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        currentPage += 1
        await loadErrors(reset: false)
    }
}
