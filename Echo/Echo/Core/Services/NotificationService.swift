import Foundation
import EchoAPI

/// Bildirim uçları (rules.md §9). Okunmamış sayısı her zaman sunucudan okunur.
nonisolated protocol NotificationServicing: Sendable {
    func list(cursor: String?, size: Int) async throws -> ListPage<NotificationItem>
    func unreadCount() async throws -> Int
    func markRead(id: String) async throws -> Int
    func markAllRead() async throws -> Int
    func preferences() async throws -> NotificationPreferences
    func updatePreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences
    func registerPushToken(_ token: String, environment: String) async throws
    func unregisterPushToken(_ token: String) async throws
}

nonisolated struct LiveNotificationService: NotificationServicing {
    let stack: EchoAPIStack

    func list(cursor: String?, size: Int) async throws -> ListPage<NotificationItem> {
        switch try await stack.client.listNotifications(.init(query: .init(cursor: cursor, size: Int32(size)))) {
        case .ok(let ok):
            let page = try ok.body.json
            return ListPage(items: page.items.map(NotificationItem.init(dto:)), nextCursor: page.nextCursor, hasMore: page.hasMore)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func unreadCount() async throws -> Int {
        switch try await stack.client.getUnreadNotificationCount(.init()) {
        case .ok(let ok): return Int(try ok.body.json.count)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func markRead(id: String) async throws -> Int {
        switch try await stack.client.markNotificationRead(.init(path: .init(id: id))) {
        case .ok(let ok): return Int(try ok.body.json.count)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func markAllRead() async throws -> Int {
        switch try await stack.client.markAllNotificationsRead(.init()) {
        case .ok(let ok): return Int(try ok.body.json.count)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func preferences() async throws -> NotificationPreferences {
        switch try await stack.client.getNotificationPreferences(.init()) {
        case .ok(let ok): return NotificationPreferences(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func updatePreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        let body = Operations.UpdateNotificationPreferences.Input.Body.json(.init(
            masterEnabled: preferences.masterEnabled,
            dailyRemindersEnabled: preferences.dailyRemindersEnabled,
            communityEnabled: preferences.communityEnabled,
            achievementsEnabled: preferences.achievementsEnabled,
            insightsEnabled: preferences.insightsEnabled,
            moodAlertsEnabled: preferences.moodAlertsEnabled,
            capsulesEnabled: preferences.capsulesEnabled,
            coachEnabled: preferences.coachEnabled,
            systemEnabled: preferences.systemEnabled,
            preferredLocalHour: Int32(preferences.preferredLocalHour),
            quietHoursStartLocal: preferences.quietHoursStartLocal.map(Int32.init),
            quietHoursEndLocal: preferences.quietHoursEndLocal.map(Int32.init),
            timezone: preferences.timezone))
        switch try await stack.client.updateNotificationPreferences(.init(body: body)) {
        case .ok(let ok): return NotificationPreferences(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func registerPushToken(_ token: String, environment: String) async throws {
        let body = Operations.RegisterPushToken.Input.Body.json(.init(token: token, platform: .init(rawValue: "ios"),
                                                                      environment: .init(rawValue: environment)))
        switch try await stack.client.registerPushToken(.init(body: body)) {
        case .created: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func unregisterPushToken(_ token: String) async throws {
        switch try await stack.client.unregisterPushToken(.init(body: .json(.init(token: token)))) {
        case .noContent: return
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
