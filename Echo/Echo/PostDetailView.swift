//
//  PostDetailView.swift
//  Echo

import SwiftUI

struct PostDetailView: View {
    let post: APICommunityPost
    @ObservedObject var communityViewModel: CommunityViewModel
    @StateObject private var viewModel: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss

    private static let serverBase = "http://localhost:8080"
    private var currentUserId: String { AppState.shared.currentUser?.id ?? "" }

    init(post: APICommunityPost, communityViewModel: CommunityViewModel) {
        self.post = post
        self.communityViewModel = communityViewModel
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.063, green: 0.098, blue: 0.133)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Post")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 24)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Post Content
                        postHeaderSection
                        postContentSection
                        postImageSection
                        postActionBar

                        Divider().background(Color.white.opacity(0.1))
                            .padding(.vertical, 8)

                        // Comments
                        if viewModel.isLoading && viewModel.comments.isEmpty {
                            HStack { Spacer(); ProgressView(); Spacer() }
                                .padding(.vertical, 32)
                        } else if viewModel.comments.isEmpty {
                            Text("No comments yet. Be the first!")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.comments) { comment in
                                    CommentCell(
                                        comment: comment,
                                        postUserId: viewModel.post.userId,
                                        currentUserId: currentUserId,
                                        isReply: false,
                                        onLike: { viewModel.toggleCommentLike(comment) },
                                        onReply: { viewModel.startReply(to: comment) },
                                        onDelete: { viewModel.deleteComment(comment) }
                                    )
                                    // Replies
                                    if let replies = comment.replies {
                                        ForEach(replies) { reply in
                                            CommentCell(
                                                comment: reply,
                                                postUserId: viewModel.post.userId,
                                                currentUserId: currentUserId,
                                                isReply: true,
                                                onLike: { viewModel.toggleCommentLike(reply) },
                                                onReply: nil,
                                                onDelete: { viewModel.deleteComment(reply) }
                                            )
                                        }
                                    }
                                }

                                if !viewModel.comments.isEmpty {
                                    Color.clear.frame(height: 1)
                                        .onAppear { viewModel.loadMoreComments() }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                .safeAreaInset(edge: .bottom) {
                    commentInputBar
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { viewModel.loadComments() }
    }

    // MARK: — Post Sections

    private var postHeaderSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.6))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(viewModel.post.authorName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.post.authorName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(viewModel.post.relativeTime)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
            }

            Spacer()

            if let emoji = viewModel.post.emoji {
                Text(emoji).font(.system(size: 24))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private var postContentSection: some View {
        Group {
            if let content = viewModel.post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.95))
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }

    private var postImageSection: some View {
        Group {
            if let imageUrl = viewModel.post.imageUrl,
               let url = URL(string: Self.serverBase + imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    case .failure:
                        Rectangle().fill(Color.white.opacity(0.05))
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                            .cornerRadius(12)
                    case .empty:
                        Rectangle().fill(Color.white.opacity(0.05))
                            .frame(height: 200)
                            .overlay(ProgressView())
                            .cornerRadius(12)
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private var postActionBar: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.togglePostLike() }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                    Text("\(viewModel.post.likesCount)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(viewModel.post.isLikedByMe
                    ? Color(red: 0.937, green: 0.267, blue: 0.267)
                    : Color(red: 0.576, green: 0.639, blue: 0.725))
            }

            HStack(spacing: 6) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 16))
                Text("\(viewModel.post.commentsCount)")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))

            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: — Comment Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))

            if let replyTo = viewModel.replyingTo {
                HStack {
                    Text("Replying to \(replyTo.displayName ?? "User")")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                    Spacer()
                    Button(action: { viewModel.cancelReply() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }

            HStack(spacing: 12) {
                TextField("Add a comment...", text: $viewModel.commentText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(red: 0.118, green: 0.161, blue: 0.231))
                    .cornerRadius(20)

                Button(action: { viewModel.sendComment() }) {
                    if viewModel.isSendingComment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray.opacity(0.3)
                                : Color(red: 0.498, green: 0.075, blue: 0.929))
                    }
                }
                .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingComment)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Color(red: 0.063, green: 0.098, blue: 0.133))
    }
}

// MARK: — Comment Cell

struct CommentCell: View {
    let comment: APIPostComment
    let postUserId: String?
    let currentUserId: String
    let isReply: Bool
    let onLike: () -> Void
    let onReply: (() -> Void)?
    let onDelete: () -> Void

    private var canDelete: Bool {
        comment.userId == currentUserId || postUserId == currentUserId
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(isReply
                    ? Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.3)
                    : Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.5))
                .frame(width: isReply ? 28 : 32, height: isReply ? 28 : 32)
                .overlay(
                    Text(String((comment.displayName ?? "U").prefix(1)))
                        .font(.system(size: isReply ? 11 : 13, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(comment.displayName ?? "User")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(comment.relativeTime)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                }

                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.9))
                    .lineSpacing(2)

                // Actions
                HStack(spacing: 16) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLikedByMe ? "heart.fill" : "heart")
                                .font(.system(size: 11))
                            Text("\(comment.likesCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(comment.isLikedByMe
                            ? Color(red: 0.937, green: 0.267, blue: 0.267)
                            : Color(red: 0.576, green: 0.639, blue: 0.725))
                    }

                    if let onReply = onReply {
                        Button(action: onReply) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 11))
                                Text("Reply")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                        }
                    }

                    if canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.7))
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(.leading, isReply ? 52 : 16)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
    }
}
