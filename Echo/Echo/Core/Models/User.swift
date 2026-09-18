import Foundation
import EchoAPI

/// Oturum açmış kullanıcı. Sayaçlar ve `recordedToday` sunucu kararıdır; istemci hesaplamaz.
nonisolated struct AuthenticatedUser: Sendable, Equatable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let timezone: String
    let language: AppLanguage
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    let moodScoreAverage: Double?
    let recordedToday: Bool
    let emailVerified: Bool
    let passwordLoginEnabled: Bool
    let isAdmin: Bool

    init(dto: Components.Schemas.UserResponse) {
        id = dto.id
        email = dto.email
        displayName = dto.displayName
        timezone = dto.timezone
        language = AppLanguage(rawValue: dto.language) ?? .deviceDefault
        currentStreak = Int(dto.currentStreak)
        longestStreak = Int(dto.longestStreak)
        totalEntries = Int(dto.totalEntries)
        moodScoreAverage = dto.moodScoreAvg
        recordedToday = dto.recordedToday
        emailVerified = dto.emailVerified
        passwordLoginEnabled = dto.passwordLoginEnabled
        isAdmin = (dto.role.value1?.rawValue ?? dto.role.value2) == "admin"
    }

    /// Kullanıcının kendi saat dilimi; geçersizse cihaz saat dilimi kullanılır.
    var resolvedTimeZone: TimeZone {
        TimeZone(identifier: timezone) ?? .current
    }
}
