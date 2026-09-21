import SwiftUI

struct CommunityFeedView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: CommunityFeedViewModel
    @State private var deletePost: CommunityPost?
    @State private var blockPost: CommunityPost?
    @State private var reportPost: CommunityPost?

    init(community: any CommunityServicing) {
        _model = State(initialValue: CommunityFeedViewModel(community: community))
    }

    var body: some View {
        VStack(spacing: AppTheme.space.sm) {
            EchoSegmentedControl(selection: $model.selectedTab, options: [
                .init(.global, String(localized: "community.tab.global")),
                .init(.following, String(localized: "community.tab.following")),
                .init(.mine, String(localized: "community.tab.mine"))
            ])
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)

            ScrollView {
                LazyVStack(spacing: AppTheme.space.sm) {
                    if let error = model.error {
                        EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                            EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.refresh() } }
                        })
                    }
                    if model.posts.isEmpty, !model.isLoading {
                        EchoEmptyState("community.empty", message: "community.emptyMessage", systemImage: "bubble.left.and.bubble.right")
                    }
                    ForEach(model.posts) { post in
                        CommunityPostCard(post: post, followTitle: followTitle(for: post),
                                          onTap: { router.push(.communityPost(id: post.id)) },
                                          onLike: { Task { await model.toggleLike(post) } },
                                          onComment: { router.push(.communityPost(id: post.id)) },
                                          onDelete: { deletePost = post },
                                          onReport: { reportPost = post },
                                          onBlock: { blockPost = post },
                                          onFollow: { Task { await model.followAction(post) } })
                            .disabled(model.workingPostID == post.id)
                            .task { if post.id == model.posts.last?.id { await model.loadNext() } }
                    }
                    if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
                }
                .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
                .padding(.bottom, AppTheme.space.xl)
            }
            .refreshable { await model.refresh() }
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("community.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EchoIconButton("square.and.pencil", accessibilityTitle: "community.create", variant: .soft) {
                    router.present(.composePost(prefilledText: nil))
                }
            }
        }
        .task(id: model.selectedTab) { await model.refresh() }
        .sheet(item: $reportPost) { post in
            CommunityReportSheet { reason, details in await model.report(post: post, reason: reason, details: details) }
                .presentationDetents([.medium, .large])
        }
        .alert("community.deleteTitle", isPresented: Binding(get: { deletePost != nil }, set: { if !$0 { deletePost = nil } })) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                guard let post = deletePost else { return }
                Task { await model.delete(post); deletePost = nil }
            }
        } message: { Text("community.deleteMessage") }
        .alert("community.blockTitle", isPresented: Binding(get: { blockPost != nil }, set: { if !$0 { blockPost = nil } })) {
            Button("common.cancel", role: .cancel) {}
            Button("community.block", role: .destructive) {
                guard let post = blockPost else { return }
                Task { _ = await model.block(post); blockPost = nil }
            }
        } message: { Text("community.blockMessage") }
    }

    private func followTitle(for post: CommunityPost) -> LocalizedStringKey? {
        guard !post.isMine, !post.isAnonymous, post.userID != nil else { return nil }
        return model.selectedTab == .following ? "community.unfollow" : "community.follow"
    }
}
