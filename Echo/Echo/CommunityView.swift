import SwiftUI
import Combine

struct CommunityView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isMenuOpen = false
    @State private var expandedPostId: String?
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(title: locManager.t("nav.community"))

                // Feed pill tabs — gradient active
                HStack(spacing: AppTheme.Spacing.sm) {
                    feedTab(locManager.t("community.global"), tab: .global)
                    feedTab(locManager.t("community.following"), tab: .following)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                .padding(.bottom, AppTheme.Spacing.md)

                if viewModel.isLoading && viewModel.posts.isEmpty {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if viewModel.posts.isEmpty {
                    if let error = viewModel.errorMessage {
                        ErrorStateView(message: error) {
                            viewModel.loadFeed()
                        }
                    } else {
                        emptyState
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            if let error = viewModel.errorMessage {
                                InlineBannerView(message: error, type: .error) {
                                    viewModel.errorMessage = nil
                                }
                            }
                            ForEach(viewModel.posts) { post in
                                CommunityPostCard(
                                    post: post,
                                    isCommentsExpanded: expandedPostId == post.id,
                                    isLikeInFlight: viewModel.isLikeInFlight(postId: post.id),
                                    onLike: { viewModel.toggleLike(post: post) },
                                    onToggleComments: {
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            expandedPostId = expandedPostId == post.id ? nil : post.id
                                        }
                                    },
                                    onPostUpdate: { viewModel.updatePostSnapshot($0) }
                                )
                            }
                            if !viewModel.posts.isEmpty {
                                Color.clear.frame(height: 1).onAppear { viewModel.loadMore() }
                            }
                        }
                        .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                        .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { viewModel.showCreatePost = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.Gradients.accent)
                            .clipShape(Circle())
                            .shadow(color: AppTheme.Colors.accent.opacity(0.5), radius: 16, y: 6)
                    }
                    .padding(.trailing, AppTheme.Layout.screenHorizontal)
                    .padding(.bottom, AppTheme.Layout.bottomFloatingOffset)
                }
            }

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }
        }
        .onAppear { viewModel.loadFeed() }
        .onDisappear { viewModel.cancelAll() }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func feedTab(_ label: String, tab: CommunityTab) -> some View {
        let isActive = viewModel.selectedTab == tab
        Button(action: { viewModel.loadFeed(tab: tab) }) {
            Text(label)
                .font(AppTheme.Typography.caption).fontWeight(.semibold)
                .foregroundColor(isActive ? .white : AppTheme.Colors.textMuted(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isActive ? AnyView(AppTheme.Gradients.accent) : AnyView(AppTheme.Colors.surface(colorScheme)))
                .cornerRadius(AppTheme.Spacing.radiusFull)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 40)).foregroundColor(AppTheme.Colors.accent)
            Text(locManager.t("community.no_posts"))
                .font(AppTheme.Typography.heading3).foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Text(locManager.t("community.no_posts_sub"))
                .font(AppTheme.Typography.body).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .multilineTextAlignment(.center).padding(.horizontal, AppTheme.Spacing.xl)
            Spacer()
        }
    }
}

// MARK: - Community Post Card

struct CommunityPostCard: View {
    let post: APICommunityPost
    let isCommentsExpanded: Bool
    let isLikeInFlight: Bool
    let onLike: () -> Void
    let onToggleComments: () -> Void
    let onPostUpdate: (APICommunityPost) -> Void
    @StateObject private var commentsViewModel: PostDetailViewModel
    @State private var showExpandedComments = false
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    private let previewCommentCount = 3
    private let expandedCommentsMaxHeight: CGFloat = 220

    init(
        post: APICommunityPost,
        isCommentsExpanded: Bool,
        isLikeInFlight: Bool = false,
        onLike: @escaping () -> Void,
        onToggleComments: @escaping () -> Void,
        onPostUpdate: @escaping (APICommunityPost) -> Void
    ) {
        self.post = post
        self.isCommentsExpanded = isCommentsExpanded
        self.isLikeInFlight = isLikeInFlight
        self.onLike = onLike
        self.onToggleComments = onToggleComments
        self.onPostUpdate = onPostUpdate
        _commentsViewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author row
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Gradients.accent)
                        .frame(width: 40, height: 40)
                    Text(String(post.authorName.prefix(1)))
                        .font(AppTheme.Typography.caption).fontWeight(.bold)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(post.authorName)
                            .font(AppTheme.Typography.caption).fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        Text("· \(post.relativeTime)")
                            .font(AppTheme.Typography.micro)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill").font(.system(size: 8))
                        Text(locManager.t("community.shared_with")).font(AppTheme.Typography.micro).fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }

                Spacer()

                if let emoji = post.emoji {
                    Text(emoji).font(.system(size: 20))
                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 4)
                        .background(AppTheme.Colors.borderSubtle(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusSm)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)

            // Content
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.9))
                    .lineSpacing(3)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                    .lineLimit(4)
            }

            // Image
            if let imageUrl = post.imageUrl,
               let url = AppConstants.API.mediaURL(for: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 240).clipped()
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                    case .failure:
                        Rectangle().fill(AppTheme.Colors.borderSubtle(colorScheme)).frame(height: 180)
                            .overlay(Image(systemName: "photo").foregroundColor(AppTheme.Colors.textMuted(colorScheme)))
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                    case .empty:
                        Rectangle().fill(AppTheme.Colors.borderSubtle(colorScheme)).frame(height: 180)
                            .overlay(ProgressView()).cornerRadius(AppTheme.Spacing.radiusMd)
                    @unknown default: EmptyView()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)
            }

            // Action bar
            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        if isLikeInFlight {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: post.isLikedByMe ? "heart.fill" : "heart").font(.system(size: 14))
                        }
                        Text("\(post.likesCount)").font(AppTheme.Typography.label).fontWeight(.semibold)
                    }
                    .foregroundColor(post.isLikedByMe ? AppTheme.Colors.destructive : AppTheme.Colors.textMuted(colorScheme))
                }
                .disabled(isLikeInFlight)

                Button(action: onToggleComments) {
                    HStack(spacing: 6) {
                        Image(systemName: isCommentsExpanded ? "bubble.right.fill" : "bubble.right")
                            .font(.system(size: 14))
                        Text("\(post.commentsCount)")
                            .font(AppTheme.Typography.label)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isCommentsExpanded ? AppTheme.Colors.accent : AppTheme.Colors.textMuted(colorScheme))
                }

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)

            if isCommentsExpanded {
                inlineCommentsSection
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(AppTheme.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
            .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
        .onChange(of: isCommentsExpanded) { _, expanded in
            if expanded && commentsViewModel.comments.isEmpty && !commentsViewModel.isLoading {
                commentsViewModel.loadComments()
            }
            if !expanded {
                showExpandedComments = false
                commentsViewModel.cancelReply()
                commentsViewModel.commentText = ""
            }
        }
        .onReceive(commentsViewModel.$post.map(\.commentsCount).removeDuplicates().dropFirst()) { newCount in
            onPostUpdate(updatedPost(withCommentsCount: newCount))
        }
        .onDisappear {
            commentsViewModel.cancelAll()
        }
    }

    private var inlineCommentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().background(AppTheme.Colors.borderSubtle(colorScheme))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                if commentsViewModel.isLoading && commentsViewModel.comments.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                } else if commentsViewModel.comments.isEmpty {
                    if let error = commentsViewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(error)
                                .font(AppTheme.Typography.label)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            Button(action: { commentsViewModel.loadComments() }) {
                                Text(locManager.t("common.retry_comments"))
                                    .font(AppTheme.Typography.label)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.Colors.accent)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    } else {
                        Text(locManager.t("common.no_comments_yet"))
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            .padding(.vertical, AppTheme.Spacing.xs)
                    }
                } else {
                    commentsListView
                    if shouldShowSeeMoreAction {
                        Button(action: handleSeeMoreTapped) {
                            Text(seeMoreButtonTitle)
                                .font(AppTheme.Typography.label)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                    }
                }

                if commentsViewModel.isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        .scaleEffect(0.9)
                }

                inlineComposer
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.sm)
            .padding(.bottom, AppTheme.Spacing.md)
        }
    }

    @ViewBuilder
    private var commentsListView: some View {
        let visibleComments = showExpandedComments
            ? commentsViewModel.comments
            : Array(commentsViewModel.comments.prefix(previewCommentCount))

        let commentsContent = LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ForEach(visibleComments) { comment in
                InlineCommentRow(comment: comment, isReply: false)
                if let replies = comment.replies, !replies.isEmpty {
                    ForEach(showExpandedComments ? replies : Array(replies.prefix(1))) { reply in
                        InlineCommentRow(comment: reply, isReply: true)
                    }
                }
            }
        }

        if showExpandedComments {
            ScrollView(showsIndicators: true) {
                commentsContent
            }
            .frame(maxHeight: expandedCommentsMaxHeight)
        } else {
            commentsContent
        }
    }

    private var inlineComposer: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            TextField(locManager.t("common.add_comment"), text: $commentsViewModel.commentText)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.background(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusFull)

            let hasText = !commentsViewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            Button(action: { commentsViewModel.sendComment() }) {
                if commentsViewModel.isSendingComment {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(hasText ? AppTheme.Colors.accent : AppTheme.Colors.textMuted(colorScheme).opacity(0.4))
                }
            }
            .disabled(!hasText || commentsViewModel.isSendingComment)
        }
    }

    private var shouldShowSeeMoreAction: Bool {
        commentsViewModel.comments.count > previewCommentCount || commentsViewModel.canLoadMoreComments
    }

    private var seeMoreButtonTitle: String {
        if !showExpandedComments { return locManager.t("common.see_more_comments") }
        if commentsViewModel.canLoadMoreComments { return locManager.t("common.load_more_comments") }
        return locManager.t("common.show_fewer_comments")
    }

    private func handleSeeMoreTapped() {
        if !showExpandedComments {
            withAnimation(.easeInOut(duration: 0.2)) {
                showExpandedComments = true
            }
            if commentsViewModel.comments.count <= previewCommentCount && commentsViewModel.canLoadMoreComments {
                commentsViewModel.loadMoreComments()
            }
            return
        }

        if commentsViewModel.canLoadMoreComments {
            commentsViewModel.loadMoreComments()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showExpandedComments = false
            }
        }
    }

    private func updatedPost(withCommentsCount count: Int) -> APICommunityPost {
        APICommunityPost(
            id: post.id,
            userId: post.userId,
            displayName: post.displayName,
            content: post.content,
            contentType: post.contentType,
            audioUrl: post.audioUrl,
            audioDuration: post.audioDuration,
            imageUrl: post.imageUrl,
            emoji: post.emoji,
            isAnonymous: post.isAnonymous,
            likesCount: post.likesCount,
            commentsCount: max(0, count),
            isLikedByMe: post.isLikedByMe,
            createdAt: post.createdAt
        )
    }
}

private struct InlineCommentRow: View {
    let comment: APIPostComment
    let isReply: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(AppTheme.Colors.accent.opacity(isReply ? 0.3 : 0.5))
                .frame(width: isReply ? 22 : 26, height: isReply ? 22 : 26)
                .overlay(
                    Text(String((comment.displayName ?? "U").prefix(1)))
                        .font(.system(size: isReply ? 9 : 10, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(comment.displayName ?? "User")
                        .font(AppTheme.Typography.label)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Text(comment.relativeTime)
                        .font(AppTheme.Typography.micro)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                Text(comment.content)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(.leading, isReply ? AppTheme.Spacing.md : 0)
    }
}

// MARK: - Border Top Helper

extension View {
    func borderTop(_ color: Color, width: CGFloat = 1) -> some View {
        VStack(spacing: 0) { Divider().background(color); self }
    }
}
