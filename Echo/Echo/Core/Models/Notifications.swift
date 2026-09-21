import Foundation
import EchoAPI

/// Bildirim. Yönlendirme `targetType` + `targetId` ile yapılır; bilinmeyen türde yönlendirme yoktur.
nonisolated struct NotificationItem: Sendable, Equatable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String?
    let targetType: EchoNotificationTarget?
    let targetID: String?
    let isRead: Bool
    let createdAt: Date
    let readAt: Date?

    init(dto: Components.Schemas.NotificationResponse) {
        id = dto.id
        type = dto._type.value1?.rawValue ?? dto._type.value2 ?? ""
        title = dto.title
        body = dto.body
        targetType = dto.targetType.map { EchoNotificationTarget(wire: $0.value1?.rawValue ?? $0.value2 ?? "") }
        targetID = dto.targetId
        isRead = dto.isRead
        createdAt = dto.createdAt
        readAt = dto.readAt
    }

    init(copying item: NotificationItem, isRead: Bool) {
        id = item.id; type = item.type; title = item.title; body = item.body
        targetType = item.targetType; targetID = item.targetID; self.isRead = isRead
        createdAt = item.createdAt; readAt = isRead ? (item.readAt ?? .now) : nil
    }
}

/// Bildirim tercihleri; saat değerleri kullanıcının saat dilimindedir.
nonisolated struct NotificationPreferences: Sendable, Equatable {
    var masterEnabled: Bool
    var dailyRemindersEnabled: Bool
    var communityEnabled: Bool
    var achievementsEnabled: Bool
    var insightsEnabled: Bool
    var moodAlertsEnabled: Bool
    var capsulesEnabled: Bool
    var coachEnabled: Bool
    var systemEnabled: Bool
    var preferredLocalHour: Int
    var quietHoursStartLocal: Int?
    var quietHoursEndLocal: Int?
    var timezone: String?

    init(dto: Components.Schemas.NotificationPreferencesResponse) {
        masterEnabled = dto.masterEnabled
        dailyRemindersEnabled = dto.dailyRemindersEnabled
        communityEnabled = dto.communityEnabled
        achievementsEnabled = dto.achievementsEnabled
        insightsEnabled = dto.insightsEnabled
        moodAlertsEnabled = dto.moodAlertsEnabled
        capsulesEnabled = dto.capsulesEnabled
        coachEnabled = dto.coachEnabled
        systemEnabled = dto.systemEnabled
        preferredLocalHour = Int(dto.preferredLocalHour)
        quietHoursStartLocal = dto.quietHoursStartLocal.map(Int.init)
        quietHoursEndLocal = dto.quietHoursEndLocal.map(Int.init)
        timezone = dto.timezone
    }
}
