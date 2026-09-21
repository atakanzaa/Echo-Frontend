import SwiftUI

@Observable
@MainActor
private final class CoachSessionsViewModel {
    private(set) var sessions: [CoachSession] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: AppError?
    @ObservationIgnored private let service: any CoachServicing
    private var nextCursor: String?
    private var hasMore = false

    init(service: any CoachServicing) { self.service = service }
    func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            let page = try await service.sessions(cursor: nil, size: 30)
            sessions = page.items; nextCursor = page.nextCursor; hasMore = page.hasMore
        } catch { self.error = AppError.displayable(error) }
    }
    func loadMore(after session: CoachSession) async {
        guard session.id == sessions.last?.id, hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.sessions(cursor: nextCursor, size: 30)
            sessions.append(contentsOf: page.items.filter { candidate in !sessions.contains { $0.id == candidate.id } })
            nextCursor = page.nextCursor; hasMore = page.hasMore
        } catch { self.error = AppError.displayable(error) }
    }
    func delete(_ session: CoachSession) async {
        do { try await service.deleteSession(id: session.id); sessions.removeAll { $0.id == session.id } }
        catch { self.error = AppError.displayable(error) }
    }
}

struct CoachSessionsView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: CoachSessionsViewModel
    @State private var pendingDeletion: CoachSession?

    init(coach: any CoachServicing) { _model = State(initialValue: CoachSessionsViewModel(service: coach)) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.space.xs) {
                if let error = model.error { EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error)) }
                if model.sessions.isEmpty, !model.isLoading {
                    EchoEmptyState("coach.sessionsEmpty", message: "coach.sessionsEmptyMessage", systemImage: "bubble.left.and.text.bubble.right") {
                        EchoButton("coach.startSession", variant: .secondary) { router.present(.coachChat(sessionId: nil)) }
                    }
                } else {
                    ForEach(model.sessions) { session in
                        EchoCard(style: .flat) {
                            HStack(spacing: AppTheme.space.xs) {
                                Button { router.present(.coachChat(sessionId: session.id)) } label: {
                                    VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                                        Text(session.title).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
                                        Text(session.updatedAt, format: .relative(presentation: .named))
                                            .echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                                        if session.isActive { Text("coach.active").echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.accent) }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                Menu {
                                    Button("common.delete", role: .destructive) { pendingDeletion = session }
                                } label: { Image(systemName: "ellipsis") }
                            }
                        }
                        .task { await model.loadMore(after: session) }
                    }
                    if model.isLoadingMore { ProgressView() }
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("coach.sessionsTitle"))
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { router.present(.coachChat(sessionId: nil)) } label: { Image(systemName: "plus") } } }
        .task { await model.load() }
        .echoRefreshable { await model.load() }
        .alert("coach.deleteTitle", isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })) {
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
            Button("common.delete", role: .destructive) {
                guard let session = pendingDeletion else { return }
                pendingDeletion = nil
                Task { await model.delete(session) }
            }
        } message: { Text("coach.deleteMessage") }
    }
}
