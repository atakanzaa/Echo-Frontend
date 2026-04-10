import Foundation
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    static let shared = NotificationViewModel()

    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var pendingNavigation: NotificationNavigation?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {}

    func refreshUnreadCount() async {
        do {
            let response: APIUnreadCountResponse = try await APIClient.shared.requestWithAutoRefresh(.getUnreadNotificationsCount)
            unreadCount = max(response.count, 0)
        } catch {
            // Fallback to local state if network fails.
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }

    func loadNotifications(page: Int = 0, size: Int = AppConstants.Pagination.defaultPageSize) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: APIPagedResponse<APINotificationItem> =
                try await APIClient.shared.requestWithAutoRefresh(.getNotifications(page: page, size: size))
            notifications = response.content.map(AppNotification.init(from:))
            unreadCount = notifications.filter { !$0.isRead }.count
            await refreshUnreadCount()
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func markRead(_ id: String) async {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        guard !notifications[idx].isRead else { return }

        notifications[idx].isRead = true
        unreadCount = max(unreadCount - 1, 0)

        do {
            let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.markNotificationRead(id: id))
        } catch {
            notifications[idx].isRead = false
            unreadCount += 1
        }
    }

    func markAllRead() async {
        let previousItems = notifications
        let previousUnread = unreadCount

        notifications = previousItems.map {
            var item = $0
            item.isRead = true
            return item
        }
        unreadCount = 0

        do {
            let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.markAllNotificationsRead)
        } catch {
            notifications = previousItems
            unreadCount = previousUnread
        }
    }

    func openNotification(_ notification: AppNotification) async {
        await markRead(notification.id)
        pendingNavigation = NotificationNavigation(tab: notification.tab)
    }

    func clearPendingNavigation() {
        pendingNavigation = nil
    }
}
