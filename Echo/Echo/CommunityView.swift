//
//  CommunityView.swift
//  Echo

import SwiftUI

struct CommunityView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            Color(red: 0.063, green: 0.098, blue: 0.133)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Community")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.149, green: 0.098, blue: 0.196))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                // Tabs
                HStack(spacing: 16) {
                    ForEach([("Global","global"), ("Following","following")], id: \.0) { label, tab in
                        Button(action: { viewModel.loadFeed(tab: tab) }) {
                            Text(label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(viewModel.selectedTab == tab ? .white : Color(red: 0.576, green: 0.639, blue: 0.725))
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(viewModel.selectedTab == tab ? Color(red: 0.149, green: 0.149, blue: 0.196) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.bottom, 16)

                if viewModel.isLoading && viewModel.posts.isEmpty {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                CommunityPostCard(
                                    post: post,
                                    onLike: { viewModel.toggleLike(post: post) },
                                    onTap: { viewModel.selectedPost = post }
                                )
                            }
                            if !viewModel.posts.isEmpty {
                                Color.clear.frame(height: 1)
                                    .onAppear { viewModel.loadMore() }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 16)
                    }
                }
            }

            // FAB — Create Post
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { viewModel.showCreatePost = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.498, green: 0.075, blue: 0.929))
                            .clipShape(Circle())
                            .shadow(color: Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }

            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .onAppear { viewModel.loadFeed() }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView(viewModel: viewModel)
        }
        .fullScreenCover(item: $viewModel.selectedPost) { post in
            PostDetailView(post: post, communityViewModel: viewModel)
        }
    }
}

// MARK: — Community Post Card

struct CommunityPostCard: View {
    let post: APICommunityPost
    let onLike: () -> Void
    let onTap: () -> Void

    private static let serverBase = "http://localhost:8080"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User Header
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(post.authorName.prefix(1)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(post.authorName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\u{2022} \(post.relativeTime)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.6))
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill").font(.system(size: 8))
                                .foregroundColor(Color(red: 0.078, green: 0.357, blue: 0.933))
                            Text("Shared with Community")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.078, green: 0.357, blue: 0.933))
                        }
                    }
                }
                Spacer()
                if let emoji = post.emoji {
                    Text(emoji).font(.system(size: 20))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.white.opacity(0.1)).cornerRadius(8)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 16)

            // Content
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.95))
                    .lineSpacing(2)
                    .padding(.horizontal, 16).padding(.vertical, 8)
            }

            // Image
            if let imageUrl = post.imageUrl,
               let url = URL(string: Self.serverBase + imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                    case .failure:
                        Rectangle().fill(Color.white.opacity(0.05))
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    case .empty:
                        Rectangle().fill(Color.white.opacity(0.05))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
                .cornerRadius(8)
            }

            // Interaction Bar
            HStack {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(post.isLikedByMe
                                ? Color(red: 0.937, green: 0.267, blue: 0.267)
                                : Color(red: 0.576, green: 0.639, blue: 0.725))
                        Text("\(post.likesCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(post.isLikedByMe
                                ? Color(red: 0.937, green: 0.267, blue: 0.267)
                                : Color(red: 0.576, green: 0.639, blue: 0.725))
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "bubble.right").font(.system(size: 12))
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                    Text("\(post.commentsCount)").font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                }
                .padding(.leading, 12)

                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.black.opacity(0.2))
        }
        .background(Color(red: 0.118, green: 0.161, blue: 0.231))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .onTapGesture { onTap() }
    }
}

// Helper for border top
extension View {
    func borderTop(_ color: Color, width: CGFloat = 1) -> some View {
        VStack(spacing: 0) {
            Divider().background(color)
            self
        }
    }
}
