import Foundation
import Combine

@MainActor
final class PostDetailViewModel: ObservableObject {

    @Published var post:             APICommunityPost
    @Published var comments:         [APIPostComment] = []
    @Published var isLoading         = false
    @Published var isLoadingMore     = false
    @Published var isSendingComment  = false
    @Published var commentText       = ""
    @Published var replyingTo:       APIPostComment? = nil
    @Published var errorMessage:     String?

    private var currentPage = 0
    private var hasMore     = true
    private let pageSize    = 20
    private let commentsTask = TaskGuard()
    private let loadMoreCommentsTask = TaskGuard()
    private let postLikeMutations = MutationGuard()
    private let commentLikeMutations = MutationGuard()

    var canLoadMoreComments: Bool { hasMore }

    init(post: APICommunityPost) {
        self.post = post
    }

    // MARK: — Load Comments

    func loadComments(reset: Bool = true) {
        commentsTask.run { [weak self] in
            await self?.performLoadComments(reset: reset)
        }
    }

    func loadMoreComments() {
        guard !isLoading, !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let page = currentPage
        loadMoreCommentsTask.run { [weak self] in
            await self?.performLoadMoreComments(page: page)
        }
    }

    // MARK: — Send Comment

    func sendComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSendingComment else { return }
        isSendingComment = true
        let parentId = replyingTo?.id
        Task {
            do {
                let body = CreateCommentBody(content: text, parentId: parentId)
                let newComment: APIPostComment = try await APIClient.shared.requestWithAutoRefresh(
                    .createComment(postId: post.id, body: body)
                )
                if let parentId = parentId,
                   let parentIdx = comments.firstIndex(where: { $0.id == parentId }) {
                    // Append reply to the parent's replies
                    let parent = comments[parentIdx]
                    var replies = parent.replies ?? []
                    replies.append(newComment)
                    comments[parentIdx] = APIPostComment(
                        id: parent.id, userId: parent.userId,
                        displayName: parent.displayName, content: parent.content,
                        parentId: parent.parentId, likesCount: parent.likesCount,
                        isLikedByMe: parent.isLikedByMe, replies: replies,
                        createdAt: parent.createdAt
                    )
                } else {
                    comments.append(newComment)
                }
                incrementCommentsCount()
                commentText  = ""
                replyingTo   = nil
                isSendingComment = false
            } catch {
                errorMessage     = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isSendingComment = false
            }
        }
    }

    // MARK: — Delete Comment

    func deleteComment(_ comment: APIPostComment) {
        Task {
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .deleteComment(postId: post.id, commentId: comment.id)
                )
                if comment.parentId != nil {
                    // Remove from parent's replies
                    for i in comments.indices {
                        if var replies = comments[i].replies,
                           replies.contains(where: { $0.id == comment.id }) {
                            replies.removeAll { $0.id == comment.id }
                            let parent = comments[i]
                            comments[i] = APIPostComment(
                                id: parent.id, userId: parent.userId,
                                displayName: parent.displayName, content: parent.content,
                                parentId: parent.parentId, likesCount: parent.likesCount,
                                isLikedByMe: parent.isLikedByMe, replies: replies,
                                createdAt: parent.createdAt
                            )
                            break
                        }
                    }
                } else {
                    comments.removeAll { $0.id == comment.id }
                }
                decrementCommentsCount()
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: — Post Like Toggle

    func togglePostLike() {
        guard postLikeMutations.start(id: post.id) else { return }
        let liked    = post.isLikedByMe
        let newCount = max(0, liked ? post.likesCount - 1 : post.likesCount + 1)
        let original = post
        post = post.copy(likesCount: newCount, isLikedByMe: !liked)
        Task {
            defer { postLikeMutations.finish(id: original.id) }
            do {
                if liked {
                    let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                        .unlikeCommunityPost(id: post.id)
                    )
                } else {
                    let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                        .likeCommunityPost(id: post.id)
                    )
                }
            } catch {
                post = original
            }
        }
    }

    // MARK: — Comment Like Toggle

    func toggleCommentLike(_ comment: APIPostComment) {
        guard commentLikeMutations.start(id: comment.id) else { return }
        let liked    = comment.isLikedByMe
        let newCount = max(0, liked ? comment.likesCount - 1 : comment.likesCount + 1)

        updateComment(comment.id) { c in
            APIPostComment(
                id: c.id, userId: c.userId, displayName: c.displayName,
                content: c.content, parentId: c.parentId,
                likesCount: newCount, isLikedByMe: !liked,
                replies: c.replies, createdAt: c.createdAt
            )
        }

        Task {
            defer { commentLikeMutations.finish(id: comment.id) }
            do {
                if liked {
                    let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                        .unlikeComment(commentId: comment.id)
                    )
                } else {
                    let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                        .likeComment(commentId: comment.id)
                    )
                }
            } catch {
                updateComment(comment.id) { _ in comment }
            }
        }
    }

    func isPostLikeInFlight() -> Bool {
        postLikeMutations.isInFlight(id: post.id)
    }

    func isCommentLikeInFlight(commentId: String) -> Bool {
        commentLikeMutations.isInFlight(id: commentId)
    }

    // MARK: — Reply

    func startReply(to comment: APIPostComment) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
    }

    // MARK: — Helpers

    private func updateComment(_ id: String, transform: (APIPostComment) -> APIPostComment) {
        // Check top-level
        if let idx = comments.firstIndex(where: { $0.id == id }) {
            comments[idx] = transform(comments[idx])
            return
        }
        // Check nested replies
        for i in comments.indices {
            if let replies = comments[i].replies,
               let rIdx = replies.firstIndex(where: { $0.id == id }) {
                var updatedReplies = replies
                updatedReplies[rIdx] = transform(replies[rIdx])
                let parent = comments[i]
                comments[i] = APIPostComment(
                    id: parent.id, userId: parent.userId,
                    displayName: parent.displayName, content: parent.content,
                    parentId: parent.parentId, likesCount: parent.likesCount,
                    isLikedByMe: parent.isLikedByMe, replies: updatedReplies,
                    createdAt: parent.createdAt
                )
                return
            }
        }
    }

    private func incrementCommentsCount() {
        post = post.copy(commentsCount: post.commentsCount + 1)
    }

    private func decrementCommentsCount() {
        post = post.copy(commentsCount: max(0, post.commentsCount - 1))
    }

    func refresh() async {
        await commentsTask.runAsync { [weak self] in
            await self?.performLoadComments(reset: true)
        }
    }

    func cancelAll() {
        commentsTask.cancel()
        loadMoreCommentsTask.cancel()
        postLikeMutations.reset()
        commentLikeMutations.reset()
    }

    private func performLoadComments(reset: Bool) async {
        if reset {
            currentPage = 0
            hasMore = true
            comments = []
        }

        guard hasMore else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let page = currentPage
            let paged: APIPagedResponse<APIPostComment> = try await APIClient.shared.requestWithAutoRefresh(
                .getPostComments(postId: post.id, page: page, size: pageSize)
            )
            guard !Task.isCancelled else { return }
            if reset {
                comments = paged.content
            } else {
                comments.appendDeduplicating(contentsOf: paged.content)
            }
            hasMore = !paged.last
            currentPage = paged.page + 1
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            isLoading = false
        }
    }

    private func performLoadMoreComments(page: Int) async {
        do {
            let paged: APIPagedResponse<APIPostComment> = try await APIClient.shared.requestWithAutoRefresh(
                .getPostComments(postId: post.id, page: page, size: pageSize)
            )
            guard !Task.isCancelled else { return }
            comments.appendDeduplicating(contentsOf: paged.content)
            hasMore = !paged.last
            currentPage = paged.page + 1
            isLoadingMore = false
        } catch is CancellationError {
            isLoadingMore = false
        } catch {
            isLoadingMore = false
        }
    }
}

extension APIPostComment {
    var relativeTime: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else { return "" }
        let diff = Int(Date().timeIntervalSince(date))
        let loc = LocalizationManager.shared
        switch diff {
        case 0..<60:
            return String(format: loc.t("common.relative.seconds_ago_fmt"), diff)
        case 60..<3600:
            return String(format: loc.t("common.relative.minutes_ago_fmt"), diff / 60)
        case 3600..<86400:
            return String(format: loc.t("common.relative.hours_ago_fmt"), diff / 3600)
        default:
            let f = DateFormatter(); f.dateStyle = .short
            return f.string(from: date)
        }
    }
}
