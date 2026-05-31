import Foundation
import Combine

@MainActor
final class NotificationPreferencesViewModel: ObservableObject {

    @Published var preferences: APINotificationPreferences?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let prefs: APINotificationPreferences = try await APIClient.shared.requestWithAutoRefresh(
                .getNotificationPreferences
            )
            preferences = prefs
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func update(_ patch: UpdateNotificationPreferencesBody) async {
        do {
            let prefs: APINotificationPreferences = try await APIClient.shared.requestWithAutoRefresh(
                .updateNotificationPreferences(patch)
            )
            preferences = prefs
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func syncCurrentTimezoneIfNeeded() async {
        let current = TimeZone.current.identifier
        guard preferences == nil || preferences?.timezone != current else { return }
        var patch = UpdateNotificationPreferencesBody()
        patch.timezone = current
        await update(patch)
    }

    func setMaster(_ value: Bool) async {
        var patch = UpdateNotificationPreferencesBody()
        patch.masterEnabled = value
        await update(patch)
    }

    func setCategory(_ category: PreferenceCategory, enabled: Bool) async {
        var patch = UpdateNotificationPreferencesBody()
        switch category {
        case .dailyReminders:  patch.dailyRemindersEnabled = enabled
        case .community:       patch.communityEnabled = enabled
        case .achievements:    patch.achievementsEnabled = enabled
        case .insights:        patch.insightsEnabled = enabled
        case .moodAlerts:      patch.moodAlertsEnabled = enabled
        case .capsules:        patch.capsulesEnabled = enabled
        case .coach:           patch.coachEnabled = enabled
        case .system:          patch.systemEnabled = enabled
        }
        await update(patch)
    }

    func setPreferredHour(_ hour: Int) async {
        var patch = UpdateNotificationPreferencesBody()
        patch.preferredLocalHour = max(0, min(23, hour))
        await update(patch)
    }

    enum PreferenceCategory: String, CaseIterable, Identifiable {
        case dailyReminders, community, achievements, insights, moodAlerts, capsules, coach, system
        var id: String { rawValue }

        var titleKey: String {
            switch self {
            case .dailyReminders: return "notifications.category.daily_reminders"
            case .community:      return "notifications.category.community"
            case .achievements:   return "notifications.category.achievements"
            case .insights:       return "notifications.category.insights"
            case .moodAlerts:     return "notifications.category.mood_alerts"
            case .capsules:       return "notifications.category.capsules"
            case .coach:          return "notifications.category.coach"
            case .system:         return "notifications.category.system"
            }
        }

        var subtitleKey: String {
            switch self {
            case .dailyReminders: return "notifications.category.daily_reminders_sub"
            case .community:      return "notifications.category.community_sub"
            case .achievements:   return "notifications.category.achievements_sub"
            case .insights:       return "notifications.category.insights_sub"
            case .moodAlerts:     return "notifications.category.mood_alerts_sub"
            case .capsules:       return "notifications.category.capsules_sub"
            case .coach:          return "notifications.category.coach_sub"
            case .system:         return "notifications.category.system_sub"
            }
        }

        var iconName: String {
            switch self {
            case .dailyReminders: return "alarm.fill"
            case .community:      return "bubble.left.and.bubble.right.fill"
            case .achievements:   return "rosette"
            case .insights:       return "sparkles"
            case .moodAlerts:     return "heart.fill"
            case .capsules:       return "hourglass"
            case .coach:          return "person.fill.questionmark"
            case .system:         return "megaphone.fill"
            }
        }

        func isEnabled(in prefs: APINotificationPreferences) -> Bool {
            switch self {
            case .dailyReminders: return prefs.dailyRemindersEnabled
            case .community:      return prefs.communityEnabled
            case .achievements:   return prefs.achievementsEnabled
            case .insights:       return prefs.insightsEnabled
            case .moodAlerts:     return prefs.moodAlertsEnabled
            case .capsules:       return prefs.capsulesEnabled
            case .coach:          return prefs.coachEnabled
            case .system:         return prefs.systemEnabled
            }
        }
    }
}
