//
//  PostDetailView.swift
//  Echo

import SwiftUI

struct PostDetailView: View {
    let post: APICommunityPost
    @ObservedObject var communityViewModel: CommunityViewModel
    @StateObject private var viewModel: PostDetailViewModel
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var currentUserId: String { AppState.shared.currentUser?.id ?? "" }
    private let topAnchorId = "post-detail-top-anchor"

    init(post: APICommunityPost, communityViewModel: CommunityViewModel) {
        self.post = post
        self.communityViewModel = communityViewModel
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    AppScreenHeader(
                        title: locManager.t("post.title"),
                        showBack: true,
                        onBack: { dismiss() }
                    )

                    Divider().background(AppTheme.Colors.border(colorScheme))

                    ScrollViewReader { proxy in
                        ScrollView {
                            Color.clear
                                .frame(height: 1)
                                .id(topAnchorId)

                            VStack(alignment: .leading, spacing: 0) {
                                postHeaderSection
                                postContentSection
                                postImageSection
                                postActionBar

                                Divider().background(AppTheme.Colors.border(colorScheme))
                                    .padding(.vertical, AppTheme.Spacing.sm)

                                if viewModel.isLoading && viewModel.comments.isEmpty {
                                    HStack { Spacer(); ProgressView(); Spacer() }
                                        .padding(.vertical, AppTheme.Spacing.xl)
                                } else if viewModel.comments.isEmpty {
                                    if let error = viewModel.errorMessage {
                                        ErrorStateView(message: error) {
                                            viewModel.loadComments()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppTheme.Spacing.xl)
                                    } else {
                                        Text(locManager.t("common.no_comments_yet"))
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, AppTheme.Spacing.xl)
                                    }
                                } else {
                                    LazyVStack(spacing: 0) {
                                        ForEach(viewModel.comments) { comment in
                                            CommentCell(
                                                comment: comment,
                                                postUserId: viewModel.post.userId,
                                                currentUserId: currentUserId,
                                                isReply: false,
                                                isLikeInFlight: viewModel.isCommentLikeInFlight(commentId: comment.id),
                                                onLike: { viewModel.toggleCommentLike(comment) },
                                                onReply: { viewModel.startReply(to: comment) },
                                                onDelete: { viewModel.deleteComment(comment) }
                                            )
                                            if let replies = comment.replies {
                                                ForEach(replies) { reply in
                                                    CommentCell(
                                                        comment: reply,
                                                        postUserId: viewModel.post.userId,
                                                        currentUserId: currentUserId,
                                                        isReply: true,
                                                        isLikeInFlight: viewModel.isCommentLikeInFlight(commentId: reply.id),
                                                        onLike: { viewModel.toggleCommentLike(reply) },
                                                        onReply: nil,
                                                        onDelete: { viewModel.deleteComment(reply) }
                                                    )
                                                }
                                            }
                                        }
                                        if !viewModel.comments.isEmpty {
                                            Color.clear.frame(height: 1).onAppear { viewModel.loadMoreComments() }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, AppTheme.Spacing.sm)
                        }
                        .safeAreaInset(edge: .bottom) { commentInputBar }
                        .onAppear {
                            DispatchQueue.main.async {
                                proxy.scrollTo(topAnchorId, anchor: .top)
                            }
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                        .id(post.id)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .onAppear { viewModel.loadComments() }
        .onDisappear { viewModel.cancelAll() }
    }

    // MARK: - Post Sections

    private var postHeaderSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(AppTheme.Colors.accent.opacity(0.55))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(viewModel.post.authorName.prefix(1)))
                        .font(AppTheme.Typography.body).fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.post.authorName)
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(viewModel.post.relativeTime)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }

            Spacer()
            if let emoji = viewModel.post.emoji { Text(emoji).font(.system(size: 24)) }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var postContentSection: some View {
        Group {
            if let content = viewModel.post.content, !content.isEmpty {
                Text(content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.95))
                    .lineSpacing(3)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.sm)
            }
        }
    }

    private var postImageSection: some View {
        Group {
            if let imageUrl = viewModel.post.imageUrl,
               let url = AppConstants.API.mediaURL(for: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity).cornerRadius(AppTheme.Spacing.radiusMd)
                    case .failure:
                        Rectangle().fill(AppTheme.Colors.borderSubtle(colorScheme))
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo").foregroundColor(AppTheme.Colors.textMuted(colorScheme)))
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                    case .empty:
                        Rectangle().fill(AppTheme.Colors.borderSubtle(colorScheme))
                            .frame(height: 200).overlay(ProgressView())
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                    @unknown default: EmptyView()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.sm)
            }
        }
    }

    private var postActionBar: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Button(action: { viewModel.togglePostLike() }) {
                HStack(spacing: 6) {
                    if viewModel.isPostLikeInFlight() {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                            .scaleEffect(0.75)
                    } else {
                        Image(systemName: viewModel.post.isLikedByMe ? "heart.fill" : "heart").font(.system(size: 16))
                    }
                    Text("\(viewModel.post.likesCount)").font(AppTheme.Typography.caption).fontWeight(.medium)
                }
                .foregroundColor(viewModel.post.isLikedByMe ? AppTheme.Colors.destructive : AppTheme.Colors.textMuted(colorScheme))
            }
            .disabled(viewModel.isPostLikeInFlight())

            HStack(spacing: 6) {
                Image(systemName: "bubble.right").font(.system(size: 16))
                Text("\(viewModel.post.commentsCount)").font(AppTheme.Typography.caption).fontWeight(.medium)
            }
            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppTheme.Colors.border(colorScheme))

            if let replyTo = viewModel.replyingTo {
                HStack {
                    Text("\(locManager.t("post.replying_to")) \(replyTo.displayName ?? locManager.t("post.user"))")
                        .font(AppTheme.Typography.micro)
                        .foregroundColor(AppTheme.Colors.accent)
                    Spacer()
                    Button(action: { viewModel.cancelReply() }) {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                TextField(locManager.t("common.add_comment"), text: $viewModel.commentText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 10)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)

                let hasText = !viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button(action: { viewModel.sendComment() }) {
                    if viewModel.isSendingComment {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(hasText ? AppTheme.Colors.accent : AppTheme.Colors.textMuted(colorScheme).opacity(0.4))
                    }
                }
                .disabled(!hasText || viewModel.isSendingComment)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .background(AppTheme.Colors.background(colorScheme))
    }
}

// MARK: - Comment Cell

struct CommentCell: View {
    let comment: APIPostComment
    let postUserId: String?
    let currentUserId: String
    let isReply: Bool
    let isLikeInFlight: Bool
    let onLike: () -> Void
    let onReply: (() -> Void)?
    let onDelete: () -> Void
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    private var canDelete: Bool { comment.userId == currentUserId || postUserId == currentUserId }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppTheme.Colors.accent.opacity(isReply ? 0.3 : 0.5))
                .frame(width: isReply ? 28 : 32, height: isReply ? 28 : 32)
                .overlay(
                    Text(String((comment.displayName ?? locManager.t("post.user")).prefix(1)))
                        .font(.system(size: isReply ? 11 : 13, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(comment.displayName ?? locManager.t("post.user"))
                        .font(AppTheme.Typography.caption).fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Text(comment.relativeTime)
                        .font(AppTheme.Typography.micro)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }

                Text(comment.content)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.9))
                    .lineSpacing(2)

                HStack(spacing: AppTheme.Spacing.md) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            if isLikeInFlight {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                                    .scaleEffect(0.65)
                            } else {
                                Image(systemName: comment.isLikedByMe ? "heart.fill" : "heart").font(.system(size: 11))
                            }
                            Text("\(comment.likesCount)").font(AppTheme.Typography.micro).fontWeight(.medium)
                        }
                        .foregroundColor(comment.isLikedByMe ? AppTheme.Colors.destructive : AppTheme.Colors.textMuted(colorScheme))
                    }
                    .disabled(isLikeInFlight)

                    if let onReply = onReply {
                        Button(action: onReply) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left").font(.system(size: 11))
                                Text(locManager.t("post.reply")).font(AppTheme.Typography.micro).fontWeight(.medium)
                            }
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        }
                    }

                    if canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash").font(.system(size: 11))
                                .foregroundColor(AppTheme.Colors.destructive.opacity(0.7))
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(.leading, isReply ? 52 : AppTheme.Spacing.md)
        .padding(.trailing, AppTheme.Spacing.md)
        .padding(.vertical, 10)
    }
}
