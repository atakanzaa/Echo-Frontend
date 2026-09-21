import SwiftUI

struct CommunityPostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: CommunityPostDetailViewModel
    @State private var reportTarget: ReportTarget?
    @State private var deleteTarget: DeleteTarget?
    @State private var blockTarget: BlockTarget?

    private enum ReportTarget: Identifiable {
        case post, comment(PostComment)
        var id: String { if case .comment(let comment) = self { return comment.id }; return "post" }
    }
    private enum DeleteTarget: Identifiable {
        case post, comment(PostComment)
        var id: String { if case .comment(let comment) = self { return comment.id }; return "post" }
    }
    private enum BlockTarget: Identifiable {
        case post, comment(PostComment)
        var id: String { if case .comment(let comment) = self { return comment.id }; return "post" }
    }

    init(id: String, community: any CommunityServicing) {
        _model = State(initialValue: CommunityPostDetailViewModel(postID: id, community: community))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.space.md) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.load() } }
                    })
                }
                if let post = model.post {
                    CommunityPostCard(post: post,
                                      onLike: { Task { await model.togglePostLike() } },
                                      onComment: {},
                                      onDelete: { deleteTarget = .post },
                                      onReport: { reportTarget = .post },
                                      onBlock: { blockTarget = .post })
                    EchoSectionHeader("community.comments")
                    ForEach(model.comments) { comment in
                        commentThread(comment)
                            .task { if comment.id == model.comments.last?.id { await model.loadMoreComments() } }
                    }
                    if model.comments.isEmpty, !model.isLoading {
                        EchoEmptyState("community.noComments", message: "community.noCommentsMessage", systemImage: "bubble.left")
                    }
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 260)
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .safeAreaInset(edge: .bottom) { commentComposer }
        .navigationTitle(Text("community.postTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .sheet(item: $reportTarget) { target in
            CommunityReportSheet { reason, details in
                switch target {
                case .post: await model.reportPost(reason: reason, details: details)
                case .comment(let comment): await model.reportComment(comment, reason: reason, details: details)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("community.deleteTitle", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) { Task { await performDelete() } }
        } message: { Text("community.deleteMessage") }
        .alert("community.blockTitle", isPresented: Binding(get: { blockTarget != nil }, set: { if !$0 { blockTarget = nil } })) {
            Button("common.cancel", role: .cancel) {}
            Button("community.block", role: .destructive) { Task { await performBlock() } }
        } message: { Text("community.blockMessage") }
    }

    private func commentThread(_ comment: PostComment) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            commentRow(comment)
            if comment.replyCount > 0, model.replies[comment.id] == nil {
                EchoButton("community.showReplies", variant: .ghost, size: .sm) { Task { await model.loadReplies(for: comment) } }
                    .padding(.leading, AppTheme.space.lg)
            }
            if let replies = model.replies[comment.id] {
                ForEach(replies) { reply in
                    commentRow(reply).padding(.leading, AppTheme.space.lg)
                }
            }
        }
    }

    private func commentRow(_ comment: PostComment) -> some View {
        EchoCard(style: .flat, padding: AppTheme.layout.cardPaddingCompact) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                HStack {
                    EchoAvatar(name: comment.displayName, size: .sm)
                    Text(comment.displayName).echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.primary)
                    Spacer()
                    Menu {
                        Button("community.reply", systemImage: "arrowshape.turn.up.left") { model.beginReply(to: comment) }
                        if !comment.isMine {
                            Button("community.report", systemImage: "exclamationmark.bubble") { reportTarget = .comment(comment) }
                            Button("community.block", systemImage: "hand.raised", role: .destructive) { blockTarget = .comment(comment) }
                        }
                        if comment.canDelete {
                            Button("common.delete", systemImage: "trash", role: .destructive) { deleteTarget = .comment(comment) }
                        }
                    } label: { Image(systemName: "ellipsis") }
                }
                if comment.moderationStatus == .visible {
                    Text(comment.content).echoTextStyle(.body).foregroundStyle(AppTheme.color.content.primary)
                } else {
                    Text("community.unavailable").echoTextStyle(.body).foregroundStyle(AppTheme.color.content.tertiary)
                }
                HStack {
                    Button { Task { await model.toggleCommentLike(comment) } } label: {
                        Label("\(comment.likesCount)", systemImage: comment.isLikedByMe ? "circle.hexagongrid.fill" : "circle.hexagongrid")
                    }
                    Button("community.reply") { model.beginReply(to: comment) }
                }
                .buttonStyle(.plain)
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.secondary)
            }
        }
    }

    private var commentComposer: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
            if let reply = model.replyingTo {
                HStack {
                    Text(String(format: String(localized: "community.replyingTo"), reply.displayName))
                        .echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.secondary)
                    Spacer()
                    Button("common.cancel") { model.cancelReply() }.echoTextStyle(.caption)
                }
            }
            HStack(alignment: .bottom, spacing: AppTheme.space.xxs) {
                TextField("community.commentPlaceholder", text: $model.draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, AppTheme.space.xs)
                    .padding(.vertical, AppTheme.space.xxs)
                    .background(RoundedRectangle(cornerRadius: AppTheme.radius.md).fill(AppTheme.color.bg.surfaceSunken))
                EchoIconButton("arrow.up", accessibilityTitle: "community.sendComment", variant: .filled) {
                    Task { await model.sendComment() }
                }
                .disabled(!model.canSend)
            }
            if model.draft.count > 500 {
                Text("community.commentTooLong").echoTextStyle(.caption).foregroundStyle(AppTheme.color.feedback.danger)
            }
        }
        .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
        .padding(.vertical, AppTheme.space.xxs)
        .background(.ultraThinMaterial)
    }

    private func performDelete() async {
        guard let target = deleteTarget else { return }
        switch target {
        case .post:
            if await model.deletePost() { dismiss() }
        case .comment(let comment):
            await model.deleteComment(comment)
        }
        deleteTarget = nil
    }

    private func performBlock() async {
        guard let target = blockTarget else { return }
        switch target {
        case .post:
            if await model.blockPostAuthor() { dismiss() }
        case .comment(let comment):
            _ = await model.blockCommentAuthor(comment)
        }
        blockTarget = nil
    }
}
