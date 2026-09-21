import Foundation
import Observation

@Observable
@MainActor
final class CommunityPostDetailViewModel {
    var draft = ""
    private(set) var post: CommunityPost?
    private(set) var comments: [PostComment] = []
    private(set) var replies: [String: [PostComment]] = [:]
    private(set) var replyingTo: PostComment?
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var error: AppError?

    let postID: String
    @ObservationIgnored private let community: any CommunityServicing
    @ObservationIgnored private var commentsCursor: String?
    @ObservationIgnored private var commentsHasMore = true
    @ObservationIgnored private var commentIntent: CommentIntent?

    private struct CommentIntent {
        let text: String
        let parentID: String?
        let key: String
    }

    init(postID: String, community: any CommunityServicing) {
        self.postID = postID
        self.community = community
    }

    var canSend: Bool {
        let count = draft.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (1...500).contains(count) && !isSending
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            post = try await community.post(id: postID)
            commentsCursor = nil
            commentsHasMore = true
            comments = []
            await loadMoreComments()
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func loadMoreComments() async {
        guard commentsHasMore else { return }
        do {
            let page = try await community.comments(postID: postID, cursor: commentsCursor, size: 30)
            comments.append(contentsOf: page.items)
            commentsCursor = page.nextCursor
            commentsHasMore = page.hasMore && page.nextCursor != nil
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func loadReplies(for comment: PostComment) async {
        guard replies[comment.id] == nil else { return }
        do {
            let page = try await community.replies(postID: postID, commentID: comment.id, cursor: nil, size: 50)
            replies[comment.id] = page.items
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func beginReply(to comment: PostComment) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
    }

    func sendComment() async {
        guard canSend || commentIntent != nil else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let intent = commentIntent ?? CommentIntent(text: trimmed, parentID: replyingTo?.id, key: UUID().uuidString)
        commentIntent = intent
        isSending = true
        error = nil
        defer { isSending = false }
        do {
            _ = try await community.createComment(postID: postID, content: intent.text,
                                                   parentID: intent.parentID, idempotencyKey: intent.key)
            commentIntent = nil
            draft = ""
            replyingTo = nil
            post = try await community.post(id: postID)
            commentsCursor = nil
            commentsHasMore = true
            comments = []
            replies = [:]
            await loadMoreComments()
        } catch {
            let appError = AppError.from(error)
            if !appError.isRetryable {
                if case .authenticationRequired = appError { /* Niyet korunur. */ }
                else { commentIntent = nil }
            }
            self.error = appError
        }
    }

    func togglePostLike() async {
        guard let post else { return }
        do {
            self.post = try await (post.isLikedByMe ? community.unlike(postID: post.id) : community.like(postID: post.id))
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func toggleCommentLike(_ comment: PostComment) async {
        do {
            let updated = try await (comment.isLikedByMe ? community.unlike(commentID: comment.id) : community.like(commentID: comment.id))
            replaceComment(updated)
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func deleteComment(_ comment: PostComment) async {
        guard comment.canDelete else { return }
        do {
            try await community.deleteComment(postID: postID, commentID: comment.id)
            post = try await community.post(id: postID)
            commentsCursor = nil
            commentsHasMore = true
            comments = []
            replies = [:]
            await loadMoreComments()
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    func deletePost() async -> Bool {
        guard post?.canDelete == true else { return false }
        do {
            try await community.deletePost(id: postID)
            return true
        } catch {
            self.error = AppError.displayable(error)
            return false
        }
    }

    func reportPost(reason: CommunityReportReason, details: String?) async -> Bool {
        await report(reason: reason, details: details) { try await community.report(postID: postID, reason: reason, details: details) }
    }

    func reportComment(_ comment: PostComment, reason: CommunityReportReason, details: String?) async -> Bool {
        await report(reason: reason, details: details) { try await community.report(commentID: comment.id, reason: reason, details: details) }
    }

    func blockPostAuthor() async -> Bool {
        do {
            try await community.blockAuthor(postID: postID)
            return true
        } catch {
            self.error = AppError.displayable(error)
            return false
        }
    }

    func blockCommentAuthor(_ comment: PostComment) async -> Bool {
        do {
            try await community.blockAuthor(commentID: comment.id)
            comments.removeAll { $0.userID == comment.userID }
            for key in Array(replies.keys) {
                replies[key]?.removeAll { $0.userID == comment.userID }
            }
            return true
        } catch {
            self.error = AppError.displayable(error)
            return false
        }
    }

    private func report(reason: CommunityReportReason, details: String?, action: () async throws -> Void) async -> Bool {
        do {
            try await action()
            return true
        } catch {
            self.error = AppError.displayable(error)
            return false
        }
    }

    private func replaceComment(_ updated: PostComment) {
        if let index = comments.firstIndex(where: { $0.id == updated.id }) {
            comments[index] = updated
            return
        }
        for key in Array(replies.keys) {
            if let index = replies[key]?.firstIndex(where: { $0.id == updated.id }) {
                replies[key]?[index] = updated
                return
            }
        }
    }
}
