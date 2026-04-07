import Foundation
import Combine

@MainActor
final class CommunityViewModel: ObservableObject {

    @Published var posts:          [APICommunityPost] = []
    @Published var selectedTab: CommunityTab = .global
    @Published var isLoading       = false
    @Published var isLoadingMore   = false
    @Published var showCreatePost  = false
    @Published var selectedPost:   APICommunityPost? = nil
    @Published var errorMessage:   String?

    private var currentPage  = 0
    private var hasMore      = true
    private let pageSize     = AppConstants.Pagination.defaultPageSize

    // MARK: — Feed

    func loadFeed(tab: CommunityTab? = nil, reset: Bool = true) {
        let activeTab = tab ?? selectedTab
        if tab != nil { selectedTab = activeTab }
        if reset {
            currentPage = 0
            hasMore     = true
            posts       = []
        }
        guard hasMore else { return }
        isLoading    = true
        errorMessage = nil
        Task {
            do {
                let paged: APIPagedResponse<APICommunityPost> = try await APIClient.shared.requestWithAutoRefresh(
                    .getCommunityFeed(tab: activeTab, page: currentPage, size: pageSize)
                )
                guard self.selectedTab == activeTab else { return }
                if reset {
                    posts = paged.content
                } else {
                    appendPosts(paged.content)
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

    func loadMore() {
        guard !isLoading, !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        Task {
            do {
                let paged: APIPagedResponse<APICommunityPost> = try await APIClient.shared.requestWithAutoRefresh(
                    .getCommunityFeed(tab: selectedTab, page: currentPage, size: pageSize)
                )
                appendPosts(paged.content)
                hasMore       = !paged.last
                currentPage   = paged.page + 1
                isLoadingMore = false
            } catch {
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                isLoadingMore = false
            }
        }
    }

    // MARK: — Like Toggle

    func toggleLike(post: APICommunityPost) {
        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let liked    = posts[idx].isLikedByMe
        let newCount = liked ? posts[idx].likesCount - 1 : posts[idx].likesCount + 1
        posts[idx]   = post.copy(likesCount: newCount, isLikedByMe: !liked)
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
                if let rollbackIdx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[rollbackIdx] = post
                }
            }
        }
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

    private func appendPosts(_ newPosts: [APICommunityPost]) {
        let existingIDs = Set(posts.map(\.id))
        posts.append(contentsOf: newPosts.filter { !existingIDs.contains($0.id) })
    }
}

extension APICommunityPost {
    var relativeTime: String {
        guard let date = DateFormatting.parseISO8601(createdAt) else { return "" }
        let diff = Int(Date().timeIntervalSince(date))
        switch diff {
        case 0..<60:     return "\(diff)s ago"
        case 60..<3600:  return "\(diff/60)m ago"
        case 3600..<86400: return "\(diff/3600)h ago"
        default:
            return DateFormatting.shortDate(from: date)
        }
    }

    var authorName: String { isAnonymous ? "Anonymous" : (displayName ?? "User") }
}
