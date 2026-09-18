import Foundation
import EchoAPI

/// Topluluk gönderisi. Sahiplik `isMine`/`canDelete`, görünürlük `moderationStatus` ile gelir;
/// yazar etiketi sunucuda çevrilir (rules.md §7).
nonisolated struct CommunityPost: Sendable, Equatable, Identifiable {
    let id: String
    let userID: String?
    let displayName: String
    let content: String?
    let contentType: EchoPostContentType
    let badgeKey: String?
    let imageURL: URL?
    let emoji: String?
    let isAnonymous: Bool
    let likesCount: Int
    let commentsCount: Int
    let isLikedByMe: Bool
    let createdAt: Date
    let isMine: Bool
    let canDelete: Bool
    let moderationStatus: EchoModerationStatus

    init(dto: Components.Schemas.CommunityPostResponse) {
        id = dto.id
        userID = dto.userId
        displayName = dto.displayName
        content = dto.content
        contentType = EchoPostContentType(wire: dto.contentType.value1?.rawValue ?? dto.contentType.value2 ?? "")
        badgeKey = dto.badgeKey
        imageURL = dto.imageUrl.flatMap(URL.init(string:))
        emoji = dto.emoji
        isAnonymous = dto.isAnonymous
        likesCount = Int(dto.likesCount)
        commentsCount = Int(dto.commentsCount)
        isLikedByMe = dto.isLikedByMe
        createdAt = dto.createdAt
        isMine = dto.isMine
        canDelete = dto.canDelete
        moderationStatus = EchoModerationStatus(wire: dto.moderationStatus.value1?.rawValue ?? dto.moderationStatus.value2 ?? "")
    }
}

/// Yorum. `postCommentsCount` gönderinin güncel toplamıdır; istemci sayaç artırmaz.
nonisolated struct PostComment: Sendable, Equatable, Identifiable {
    let id: String
    let userID: String?
    let displayName: String
    let content: String
    let parentID: String?
    let likesCount: Int
    let isLikedByMe: Bool
    let createdAt: Date
    let replyCount: Int
    let postCommentsCount: Int
    let isMine: Bool
    let canDelete: Bool
    let moderationStatus: EchoModerationStatus

    init(dto: Components.Schemas.PostCommentResponse) {
        id = dto.id
        userID = dto.userId
        displayName = dto.displayName
        content = dto.content
        parentID = dto.parentId
        likesCount = Int(dto.likesCount)
        isLikedByMe = dto.isLikedByMe
        createdAt = dto.createdAt
        replyCount = Int(dto.replyCount)
        postCommentsCount = Int(dto.postCommentsCount)
        isMine = dto.isMine
        canDelete = dto.canDelete
        moderationStatus = EchoModerationStatus(wire: dto.moderationStatus.value1?.rawValue ?? dto.moderationStatus.value2 ?? "")
    }
}

/// Engellenen yazar kaydı.
nonisolated struct CommunityBlock: Sendable, Equatable, Identifiable {
    let id: String
    let displayName: String?
    let createdAt: Date

    init(dto: Components.Schemas.CommunityBlockResponse) {
        id = dto.id
        displayName = dto.displayName
        createdAt = dto.createdAt
    }
}

/// Şikâyet nedenleri sunucunun sabit sözlüğüdür.
nonisolated enum CommunityReportReason: String, CaseIterable, Sendable, Identifiable {
    case spam
    case harassment
    case hate
    case sexualContent = "sexual_content"
    case violence
    case selfHarm = "self_harm"
    case other

    var id: String { rawValue }
}
