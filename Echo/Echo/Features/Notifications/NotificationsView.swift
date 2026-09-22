import SwiftUI

@Observable
@MainActor
private final class NotificationsViewModel {
    private(set) var items: [NotificationItem] = []
    private(set) var unreadCount = 0
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: AppError?
    @ObservationIgnored private let service: any NotificationServicing
    private var nextCursor: String?
    private var hasMore = false

    init(service: any NotificationServicing) { self.service = service }

    func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            async let page = service.list(cursor: nil, size: 30)
            async let count = service.unreadCount()
            let (loadedPage, loadedCount) = try await (page, count)
            items = loadedPage.items
            nextCursor = loadedPage.nextCursor
            hasMore = loadedPage.hasMore
            unreadCount = loadedCount
        } catch { self.error = AppError.displayable(error) }
    }

    func loadMore(after item: NotificationItem) async {
        guard item.id == items.last?.id, hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.list(cursor: nextCursor, size: 30)
            items.append(contentsOf: page.items.filter { candidate in !items.contains { $0.id == candidate.id } })
            nextCursor = page.nextCursor; hasMore = page.hasMore
        } catch { self.error = AppError.displayable(error) }
    }

    func markRead(_ item: NotificationItem) async {
        guard !item.isRead else { return }
        do {
            unreadCount = try await service.markRead(id: item.id)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                let current = items[index]
                items[index] = NotificationItem(copying: current, isRead: true)
            }
        } catch { self.error = AppError.displayable(error) }
    }

    func markAllRead() async {
        do {
            unreadCount = try await service.markAllRead()
            items = items.map { NotificationItem(copying: $0, isRead: true) }
        } catch { self.error = AppError.displayable(error) }
    }
}

struct NotificationsView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: NotificationsViewModel

    init(notifications: any NotificationServicing) {
        _model = State(initialValue: NotificationsViewModel(service: notifications))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.space.xs) {
                if let error = model.error { EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error)) }
                if model.items.isEmpty, !model.isLoading {
                    EchoEmptyState("notifications.empty", message: "notifications.emptyMessage", systemImage: "bell")
                } else {
                    ForEach(model.items) { item in
                        Button { Task { await open(item) } } label: { notificationRow(item) }
                            .buttonStyle(.plain)
                            .task { await model.loadMore(after: item) }
                    }
                    if model.isLoadingMore { ProgressView() }
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("notifications.title"))
        .toolbar {
            if model.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await model.markAllRead() } } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .accessibilityLabel(Text("notifications.markAllRead"))
                }
            }
        }
        .task { await model.load() }
        .echoRefreshable { await model.load() }
    }

    private func notificationRow(_ item: NotificationItem) -> some View {
        EchoCard(style: item.isRead ? .flat : .raised) {
            HStack(alignment: .top, spacing: AppTheme.space.xs) {
                Image(systemName: icon(for: item.targetType))
                    .foregroundStyle(AppTheme.color.content.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                    Text(item.title).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
                    if let body = item.body { Text(body).echoTextStyle(.body).foregroundStyle(AppTheme.color.content.secondary) }
                    Text(item.createdAt, format: .relative(presentation: .named))
                        .echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.tertiary)
                }
                Spacer(minLength: 0)
                if !item.isRead { Circle().fill(AppTheme.color.accent.primary).frame(width: 8, height: 8).accessibilityLabel(Text("notifications.unread")) }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func open(_ item: NotificationItem) async {
        await model.markRead(item)
        guard let target = item.targetType else { return }
        router.open(target, id: item.targetID)
    }

    private func icon(for target: EchoNotificationTarget?) -> String {
        switch target {
        case .journalEntry, .journal: "book"
        case .achievement: "medal"
        case .post: "bubble.left.and.bubble.right"
        case .coach: "sparkles"
        case .insights: "chart.line.uptrend.xyaxis"
        case .capsule: "hourglass"
        default: "bell"
        }
    }
}
