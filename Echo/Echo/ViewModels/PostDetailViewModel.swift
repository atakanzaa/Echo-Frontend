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
    private let pageSize    = AppConstants.Pagination.defaultPageSize

    init(post: APICommunityPost) {
        self.post = post
    }

    // MARK: — Load Comments

    func loadComments(reset: Bool = true) {
        if reset {
            currentPage = 0
            hasMore     = true
            comments    = []
        }
        guard hasMore, !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let paged: APIPagedResponse<APIPostComment> = try await APIClient.shared.requestWithAutoRefresh(
                    .getPostComments(postId: post.id, page: currentPage, size: pageSize)
                )
                if reset {
                    comments = paged.content
                } else {
                    appendComments(paged.content)
                }
                hasMore     = !paged.last
                currentPage = paged.page + 1
                isLoading   = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoading    = false
            }
        }
    }

    func loadMoreComments() {
        guard !isLoading, !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        Task {
            do {
                let paged: APIPagedResponse<APIPostComment> = try await APIClient.shared.requestWithAutoRefresh(
                    .getPostComments(postId: post.id, page: currentPage, size: pageSize)
                )
                appendComments(paged.content)
                hasMore       = !paged.last
                currentPage   = paged.page + 1
                isLoadingMore = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoadingMore = false
            }
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
                    comments[parentIdx] = parent.copy(replies: replies)
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
                            comments[i] = comments[i].copy(replies: replies)
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
        let liked    = post.isLikedByMe
        let newCount = liked ? post.likesCount - 1 : post.likesCount + 1
        let original = post
        post = post.copy(likesCount: newCount, isLikedByMe: !liked)
        Task {
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
        let liked    = comment.isLikedByMe
        let newCount = liked ? comment.likesCount - 1 : comment.likesCount + 1

        updateComment(comment.id) { c in
            c.copy(likesCount: newCount, isLikedByMe: !liked)
        }

        Task {
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
                comments[i] = comments[i].copy(replies: updatedReplies)
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

    private func appendComments(_ newComments: [APIPostComment]) {
        let existingIDs = Set(comments.map(\.id))
        comments.append(contentsOf: newComments.filter { !existingIDs.contains($0.id) })
    }
}

extension APIPostComment {
    var relativeTime: String {
        guard let date = DateFormatting.parseISO8601(createdAt) else { return "" }
        let diff = Int(Date().timeIntervalSince(date))
        switch diff {
        case 0..<60:       return "\(diff)s ago"
        case 60..<3600:    return "\(diff/60)m ago"
        case 3600..<86400: return "\(diff/3600)h ago"
        default:
            return DateFormatting.shortDate(from: date)
        }
    }
}
