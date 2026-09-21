import SwiftUI

struct CommunityPostCard: View {
    let post: CommunityPost
    var followTitle: LocalizedStringKey?
    var onTap: (() -> Void)?
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onDelete: (() -> Void)?
    var onReport: (() -> Void)?
    var onBlock: (() -> Void)?
    var onFollow: (() -> Void)?

    var body: some View {
        EchoCard(style: .standard) {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                header
                content
                actions
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    private var header: some View {
        HStack(spacing: AppTheme.space.xs) {
            if post.isAnonymous {
                EchoRippleView(ringCount: 2, intensity: 0.45, isAnimating: false)
                    .frame(width: 40, height: 40)
            } else {
                EchoAvatar(name: post.displayName)
            }
            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                Text(post.displayName).echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.primary)
                Text(post.createdAt, format: .relative(presentation: .named))
                    .echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
            }
            Spacer(minLength: 0)
            Menu {
                if let followTitle, let onFollow {
                    Button(followTitle, systemImage: "person.badge.plus", action: onFollow)
                }
                if !post.isMine {
                    if let onReport { Button("community.report", systemImage: "exclamationmark.bubble", action: onReport) }
                    if let onBlock { Button("community.block", systemImage: "hand.raised", role: .destructive, action: onBlock) }
                }
                if post.canDelete, let onDelete {
                    Button("common.delete", systemImage: "trash", role: .destructive, action: onDelete)
                }
            } label: {
                Image(systemName: "ellipsis").frame(width: AppTheme.layout.minTouchTarget, height: AppTheme.layout.minTouchTarget)
            }
            .foregroundStyle(AppTheme.color.content.secondary)
            .accessibilityLabel(Text("community.moreActions"))
        }
    }

    @ViewBuilder private var content: some View {
        switch post.moderationStatus {
        case .visible:
            visibleContent
        case .underReview:
            EchoBanner(kind: .warning, title: String(localized: "community.underReview"))
            if post.isMine { visibleContent }
        case .removed:
            Text("community.removed").echoTextStyle(.body).foregroundStyle(AppTheme.color.content.tertiary)
        case .unknown:
            Text("community.unavailable").echoTextStyle(.body).foregroundStyle(AppTheme.color.content.tertiary)
        }
    }

    @ViewBuilder private var visibleContent: some View {
        if let emoji = post.emoji, !emoji.isEmpty {
            Text(emoji).font(.system(size: 34)).accessibilityHidden(true)
        }
        if let text = post.content, !text.isEmpty {
            Text(text)
                .echoTextStyle(.entry)
                .foregroundStyle(AppTheme.color.content.primary)
                .lineLimit(6)
        }
        if let imageURL = post.imageURL {
            // Sabit oranlı kutu: görsel yüklenmeden önce ve sonra kartın boyu aynı; kaydırırken liste sıçramaz.
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay { CachedRemoteImage(url: imageURL) }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous))
        }
    }

    private var actions: some View {
        HStack(spacing: AppTheme.space.sm) {
            Button(action: { onLike?() }) {
                Label("\(post.likesCount)", systemImage: post.isLikedByMe ? "circle.hexagongrid.fill" : "circle.hexagongrid")
            }
            .foregroundStyle(post.isLikedByMe ? AppTheme.color.content.accent : AppTheme.color.content.secondary)
            Button(action: { onComment?() }) {
                Label("\(post.commentsCount)", systemImage: "bubble.left")
            }
            .foregroundStyle(AppTheme.color.content.secondary)
            Spacer()
            if let content = post.content, !content.isEmpty {
                ShareLink(item: content) { Image(systemName: "square.and.arrow.up") }
                    .foregroundStyle(AppTheme.color.content.secondary)
            }
        }
        .echoTextStyle(.subhead)
        .buttonStyle(.plain)
    }
}
