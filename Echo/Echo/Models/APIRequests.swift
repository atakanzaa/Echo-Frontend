import Foundation

// MARK: — Auth

struct RegisterBody: Encodable {
    let email:       String
    let password:    String
    let displayName: String
    let timezone:    String
}

struct LoginBody: Encodable {
    let email:    String
    let password: String
}

struct RefreshBody: Encodable {
    let refreshToken: String
}

struct LogoutBody: Encodable {
    let refreshToken: String
}

// MARK: — Profile

struct UpdateProfileBody: Encodable {
    let displayName: String?
    let timezone:    String?
}

// MARK: — Community

struct CreatePostBody: Encodable {
    let content:     String
    let contentType: PostContentType
    let emoji:       String?
    let isAnonymous: Bool
}

struct CreateCommentBody: Encodable {
    let content:  String
    let parentId: String?
}

// MARK: — Coach

struct SendCoachMessageBody: Encodable {
    let content: String
    let role:    CoachMessageRole
}

/// Journal hakkinda coach oturumu baslatma
struct CreateCoachSessionBody: Encodable {
    let journalEntryId: String
}

// MARK: — Time Capsule

struct CreateCapsuleBody: Encodable {
    let title:       String?
    let contentText: String?
    let contentType: CapsuleContentType
    let unlockAt:    String   // ISO 8601
}

// MARK: — Admin

struct AIConfigBody: Encodable {
    let provider: String   // "openai" | "gemini" | "claude"
}
