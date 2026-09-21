import Foundation
import Observation

@Observable
@MainActor
final class CommunityFeedViewModel {
    enum Tab: String, Hashable, CaseIterable {
        case global, following, mine
    }

    var selectedTab: Tab = .global
    private(set) var posts: [CommunityPost] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var workingPostID: String?
    private(set) var error: AppError?

    @ObservationIgnored private let community: any CommunityServicing
    @ObservationIgnored private var cursor: String?
    @ObservationIgnored private var loadID = UUID()

    init(community: any CommunityServicing) {
        self.community = community
    }

    func refresh() async {
        let requestedTab = selectedTab
        let requestID = UUID()
        loadID = requestID
        isLoading = true
        error = nil
        do {
            let page = try await community.feed(tab: requestedTab.rawValue, cursor: nil, size: 20)
            try Task.checkCancellation()
            guard loadID == requestID, selectedTab == requestedTab else { return }
            posts = page.items
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
            isLoading = false
        } catch is CancellationError {
            if loadID == requestID { isLoading = false }
        } catch {
            guard loadID == requestID else { return }
            self.error = AppError.from(error)
            isLoading = false
        }
    }

    func loadNext() async {
        guard !isLoading, hasMore else { return }
        let requestedTab = selectedTab
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let page = try await community.feed(tab: requestedTab.rawValue, cursor: cursor, size: 20)
            guard selectedTab == requestedTab else { return }
            posts.append(contentsOf: page.items)
            cursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor != nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    func toggleLike(_ post: CommunityPost) async {
        guard workingPostID == nil else { return }
        workingPostID = post.id
        defer { workingPostID = nil }
        do {
            let updated = try await (post.isLikedByMe ? community.unlike(postID: post.id) : community.like(postID: post.id))
            replace(updated)
        } catch {
            self.error = AppError.from(error)
        }
    }

    func delete(_ post: CommunityPost) async {
        guard post.canDelete, workingPostID == nil else { return }
        workingPostID = post.id
        defer { workingPostID = nil }
        do {
            try await community.deletePost(id: post.id)
            posts.removeAll { $0.id == post.id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func report(post: CommunityPost, reason: CommunityReportReason, details: String?) async -> Bool {
        do {
            try await community.report(postID: post.id, reason: reason, details: details)
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    func block(_ post: CommunityPost) async -> Bool {
        do {
            try await community.blockAuthor(postID: post.id)
            posts.removeAll { $0.userID == post.userID }
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    func followAction(_ post: CommunityPost) async {
        guard let userID = post.userID, !post.isMine else { return }
        do {
            if selectedTab == .following {
                try await community.unfollow(userID: userID)
                posts.removeAll { $0.userID == userID }
            } else {
                try await community.follow(userID: userID)
            }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func insertCreated(_ post: CommunityPost) {
        if selectedTab == .mine || selectedTab == .global { posts.insert(post, at: 0) }
    }

    private func replace(_ post: CommunityPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }
}
