import SwiftUI

@Observable
@MainActor
private final class BlockedAuthorsViewModel {
    private(set) var blocks: [CommunityBlock] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var error: AppError?
    @ObservationIgnored private let community: any CommunityServicing
    @ObservationIgnored private var cursor: String?

    init(community: any CommunityServicing) { self.community = community }

    /// Liste boşaltılmaz; ilk sayfa gelince yerine konur.
    func refresh() async {
        do {
            let page = try await community.blocks(cursor: nil, size: 30)
            blocks = page.items
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
        } catch { self.error = AppError.displayable(error) }
    }

    func loadNext() async {
        guard !isLoading, hasMore else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            let page = try await community.blocks(cursor: cursor, size: 30)
            blocks.append(contentsOf: page.items)
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
        } catch { self.error = AppError.displayable(error) }
    }

    func unblock(_ block: CommunityBlock) async {
        do {
            try await community.removeBlock(id: block.id)
            blocks.removeAll { $0.id == block.id }
        } catch { self.error = AppError.displayable(error) }
    }
}

struct BlockedAuthorsView: View {
    @State private var model: BlockedAuthorsViewModel

    init(community: any CommunityServicing) {
        _model = State(initialValue: BlockedAuthorsViewModel(community: community))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.space.xs) {
                if let error = model.error { EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error)) }
                if model.blocks.isEmpty, !model.isLoading {
                    EchoEmptyState("blocked.empty", message: "blocked.emptyMessage", systemImage: "hand.raised")
                }
                ForEach(model.blocks) { block in
                    EchoCard(style: .flat) {
                        HStack {
                            EchoAvatar(name: block.displayName)
                            Text(block.displayName ?? String(localized: "blocked.unknownAuthor"))
                                .echoTextStyle(.body).foregroundStyle(AppTheme.color.content.primary)
                            Spacer()
                            EchoButton("blocked.unblock", variant: .ghost, size: .sm) { Task { await model.unblock(block) } }
                        }
                    }
                    .task { if block.id == model.blocks.last?.id { await model.loadNext() } }
                }
                if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("blocked.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.refresh() }
        .echoRefreshable { await model.refresh() }
    }
}
