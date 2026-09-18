import Foundation
import EchoAPI
import OpenAPIRuntime

/// Topluluk uçları (rules.md §7). Beğeni ve yorum yanıtları güncel sayaçlarla döner.
nonisolated protocol CommunityServicing: Sendable {
    func feed(tab: String, cursor: String?, size: Int) async throws -> ListPage<CommunityPost>
    func post(id: String) async throws -> CommunityPost
    func createPost(content: String?, emoji: String?, isAnonymous: Bool, badgeKey: String?, idempotencyKey: String) async throws -> CommunityPost
    func createImagePost(imageData: Data, filename: String, content: String?, emoji: String?, isAnonymous: Bool, badgeKey: String?, idempotencyKey: String) async throws -> CommunityPost
    func deletePost(id: String) async throws
    func like(postID: String) async throws -> CommunityPost
    func unlike(postID: String) async throws -> CommunityPost
    func comments(postID: String, cursor: String?, size: Int) async throws -> ListPage<PostComment>
    func replies(postID: String, commentID: String, cursor: String?, size: Int) async throws -> ListPage<PostComment>
    func createComment(postID: String, content: String, parentID: String?, idempotencyKey: String) async throws -> PostComment
    func deleteComment(postID: String, commentID: String) async throws
    func like(commentID: String) async throws -> PostComment
    func unlike(commentID: String) async throws -> PostComment
    func report(postID: String, reason: CommunityReportReason, details: String?) async throws
    func report(commentID: String, reason: CommunityReportReason, details: String?) async throws
    func blockAuthor(postID: String) async throws
    func blockAuthor(commentID: String) async throws
    func blocks(cursor: String?, size: Int) async throws -> ListPage<CommunityBlock>
    func removeBlock(id: String) async throws
    func follow(userID: String) async throws
    func unfollow(userID: String) async throws
}

nonisolated struct LiveCommunityService: CommunityServicing {
    let stack: EchoAPIStack

    func feed(tab: String, cursor: String?, size: Int) async throws -> ListPage<CommunityPost> {
        let query = Operations.GetCommunityFeed.Input.Query(tab: .init(rawValue: tab), cursor: cursor, size: Int32(size))
        switch try await stack.client.getCommunityFeed(.init(query: query)) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(CommunityPost.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func post(id: String) async throws -> CommunityPost {
        switch try await stack.client.getCommunityPost(.init(path: .init(postId: id))) {
        case .ok(let ok): return CommunityPost(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func createPost(content: String?, emoji: String?, isAnonymous: Bool, badgeKey: String?, idempotencyKey: String) async throws -> CommunityPost {
        let body = Components.Schemas.CreatePostRequest(content: content, emoji: emoji, isAnonymous: isAnonymous, badgeKey: badgeKey)
        let input = Operations.CreateCommunityPost.Input(query: .init(), headers: .init(idempotencyKey: idempotencyKey), body: .json(body))
        switch try await stack.client.createCommunityPost(input) {
        case .created(let created): return CommunityPost(dto: try created.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func createImagePost(imageData: Data, filename: String, content: String?, emoji: String?, isAnonymous: Bool, badgeKey: String?, idempotencyKey: String) async throws -> CommunityPost {
        let payload = Operations.CreateCommunityPost.Input.Body.MultipartFormPayload.ImagePayload(body: HTTPBody(imageData))
        let input = Operations.CreateCommunityPost.Input(
            query: .init(content: content, emoji: emoji, isAnonymous: isAnonymous, badgeKey: badgeKey),
            headers: .init(idempotencyKey: idempotencyKey),
            body: .multipartForm([.image(.init(payload: payload, filename: filename))]))
        switch try await stack.client.createCommunityPost(input) {
        case .created(let created): return CommunityPost(dto: try created.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func deletePost(id: String) async throws {
        switch try await stack.client.deleteCommunityPost(.init(path: .init(postId: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func like(postID: String) async throws -> CommunityPost {
        switch try await stack.client.likePost(.init(path: .init(postId: postID))) {
        case .ok(let ok): return CommunityPost(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func unlike(postID: String) async throws -> CommunityPost {
        switch try await stack.client.unlikePost(.init(path: .init(postId: postID))) {
        case .ok(let ok): return CommunityPost(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func comments(postID: String, cursor: String?, size: Int) async throws -> ListPage<PostComment> {
        let input = Operations.ListPostComments.Input(path: .init(postId: postID), query: .init(cursor: cursor, size: Int32(size)))
        switch try await stack.client.listPostComments(input) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(PostComment.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func replies(postID: String, commentID: String, cursor: String?, size: Int) async throws -> ListPage<PostComment> {
        let input = Operations.ListCommentReplies.Input(path: .init(postId: postID, commentId: commentID),
                                                        query: .init(cursor: cursor, size: Int32(size)))
        switch try await stack.client.listCommentReplies(input) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(PostComment.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func createComment(postID: String, content: String, parentID: String?, idempotencyKey: String) async throws -> PostComment {
        let input = Operations.CreatePostComment.Input(path: .init(postId: postID),
                                                        headers: .init(idempotencyKey: idempotencyKey),
                                                        body: .json(.init(content: content, parentId: parentID)))
        switch try await stack.client.createPostComment(input) {
        case .created(let created): return PostComment(dto: try created.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func deleteComment(postID: String, commentID: String) async throws {
        switch try await stack.client.deletePostComment(.init(path: .init(postId: postID, commentId: commentID))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func like(commentID: String) async throws -> PostComment {
        switch try await stack.client.likeComment(.init(path: .init(commentId: commentID))) {
        case .ok(let ok): return PostComment(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func unlike(commentID: String) async throws -> PostComment {
        switch try await stack.client.unlikeComment(.init(path: .init(commentId: commentID))) {
        case .ok(let ok): return PostComment(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func report(postID: String, reason: CommunityReportReason, details: String?) async throws {
        let input = Operations.ReportPost.Input(path: .init(postId: postID),
                                                 body: .json(.init(reason: .init(rawValue: reason.rawValue) ?? .other, details: details)))
        switch try await stack.client.reportPost(input) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func report(commentID: String, reason: CommunityReportReason, details: String?) async throws {
        let input = Operations.ReportComment.Input(path: .init(commentId: commentID),
                                                    body: .json(.init(reason: .init(rawValue: reason.rawValue) ?? .other, details: details)))
        switch try await stack.client.reportComment(input) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func blockAuthor(postID: String) async throws {
        switch try await stack.client.blockPostAuthor(.init(path: .init(postId: postID))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func blockAuthor(commentID: String) async throws {
        switch try await stack.client.blockCommentAuthor(.init(path: .init(commentId: commentID))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func blocks(cursor: String?, size: Int) async throws -> ListPage<CommunityBlock> {
        switch try await stack.client.listCommunityBlocks(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(CommunityBlock.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func removeBlock(id: String) async throws {
        switch try await stack.client.deleteCommunityBlock(.init(path: .init(blockId: id))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func follow(userID: String) async throws {
        switch try await stack.client.followUser(.init(path: .init(userId: userID))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func unfollow(userID: String) async throws {
        switch try await stack.client.unfollowUser(.init(path: .init(userId: userID))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
