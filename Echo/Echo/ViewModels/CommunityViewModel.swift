import Foundation
import Combine

@MainActor
final class CommunityViewModel: ObservableObject {

    @Published var posts:          [APICommunityPost] = []
    @Published var selectedTab     = CommunityTab.global.rawValue
    @Published var isLoading       = false
    @Published var isLoadingMore   = false
    @Published var showCreatePost  = false
    @Published var errorMessage:   String?

    private var currentPage  = 0
    private var hasMore      = true
    private let pageSize     = 20
    private let feedTask     = TaskGuard()
    private let loadMoreTask = TaskGuard()
    private let likeMutations = MutationGuard()

    // MARK: — Feed

    func loadFeed(tab: String? = nil, reset: Bool = true) {
        let activeTab = tab ?? selectedTab
        if tab != nil { selectedTab = activeTab }
        feedTask.run { [weak self] in
            await self?.performLoadFeed(activeTab: activeTab, reset: reset)
        }
    }

    func loadMore() {
        guard !isLoading, !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let tab = selectedTab
        let page = currentPage
        loadMoreTask.run { [weak self] in
            await self?.performLoadMore(activeTab: tab, page: page)
        }
    }

    // MARK: — Like Toggle

    func toggleLike(post: APICommunityPost) {
        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else { return }
        guard likeMutations.start(id: post.id) else { return }
        let liked    = posts[idx].isLikedByMe
        let newCount = max(0, liked ? posts[idx].likesCount - 1 : posts[idx].likesCount + 1)
        posts[idx]   = APICommunityPost(
            id:            post.id,
            userId:        post.userId,
            displayName:   post.displayName,
            content:       post.content,
            contentType:   post.contentType,
            audioUrl:      post.audioUrl,
            audioDuration: post.audioDuration,
            imageUrl:      post.imageUrl,
            emoji:         post.emoji,
            isAnonymous:   post.isAnonymous,
            likesCount:    newCount,
            commentsCount: post.commentsCount,
            isLikedByMe:   !liked,
            createdAt:     post.createdAt
        )
        Task {
            defer { likeMutations.finish(id: post.id) }
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
                if let rollbackIdx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[rollbackIdx] = post
                }
            }
        }
    }

    func isLikeInFlight(postId: String) -> Bool {
        likeMutations.isInFlight(id: postId)
    }

    // MARK: — Create Post

    func createPost(content: String?, emoji: String?, isAnonymous: Bool, imageData: Data?, imageName: String?) async throws {
        let response: APICommunityPost
        if let imageData = imageData, let imageName = imageName {
            response = try await APIClient.shared.uploadWithAutoRefresh(
                .createCommunityPostWithImage(
                    imageData: imageData, filename: imageName,
                    content: content, emoji: emoji, isAnonymous: isAnonymous
                )
            )
        } else {
            let body = CreatePostBody(
                content: content ?? "", contentType: .text,
                emoji: emoji, isAnonymous: isAnonymous
            )
            response = try await APIClient.shared.requestWithAutoRefresh(
                .createCommunityPost(body)
            )
        }
        posts.insert(response, at: 0)
    }

    // MARK: — Delete Post

    func deletePost(postId: String) {
        Task {
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .deleteCommunityPost(id: postId)
                )
                posts.removeAll { $0.id == postId }
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: — Follow / Unfollow

    func followUser(userId: String) {
        Task {
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .followUser(userId: userId)
                )
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    func unfollowUser(userId: String) {
        Task {
            do {
                let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                    .unfollowUser(userId: userId)
                )
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }

    /// Keeps feed cards in sync when an inline comment action mutates a post snapshot.
    func updatePostSnapshot(_ updated: APICommunityPost) {
        guard let idx = posts.firstIndex(where: { $0.id == updated.id }) else { return }
        posts[idx] = updated
    }

    func refresh() async {
        let tab = selectedTab
        await feedTask.runAsync { [weak self] in
            await self?.performLoadFeed(activeTab: tab, reset: true)
        }
    }

    func cancelAll() {
        feedTask.cancel()
        loadMoreTask.cancel()
        likeMutations.reset()
    }

    private func performLoadFeed(activeTab: String, reset: Bool) async {
        if reset {
            currentPage = 0
            hasMore = true
            posts = []
        }

        guard hasMore else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let page = currentPage
            let tabValue = CommunityTab(rawValue: activeTab) ?? .global
            let paged: APIPagedResponse<APICommunityPost> = try await APIClient.shared.requestWithAutoRefresh(
                .getCommunityFeed(tab: tabValue, page: page, size: pageSize)
            )
            guard !Task.isCancelled else { return }
            guard selectedTab == activeTab else {
                isLoading = false
                return
            }
            if reset {
                posts = paged.content
            } else {
                posts.appendDeduplicating(contentsOf: paged.content)
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

    private func performLoadMore(activeTab: String, page: Int) async {
        do {
            let tabValue = CommunityTab(rawValue: activeTab) ?? .global
            let paged: APIPagedResponse<APICommunityPost> = try await APIClient.shared.requestWithAutoRefresh(
                .getCommunityFeed(tab: tabValue, page: page, size: pageSize)
            )
            guard !Task.isCancelled else { return }
            guard selectedTab == activeTab else {
                isLoadingMore = false
                return
            }
            posts.appendDeduplicating(contentsOf: paged.content)
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

extension APICommunityPost {
    var relativeTime: String {
        guard let date = DateFormatting.parseISO8601(createdAt) else { return "" }
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

    var authorName: String {
        if isAnonymous { return LocalizationManager.shared.t("common.anonymous") }
        return displayName ?? LocalizationManager.shared.t("common.user")
    }
}
