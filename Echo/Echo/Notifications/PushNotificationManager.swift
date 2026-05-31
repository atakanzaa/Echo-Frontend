import Foundation
import Combine
import OSLog
import UIKit
import UserNotifications

@MainActor
final class PushNotificationManager: NSObject, ObservableObject {

    static let shared = PushNotificationManager()

    @Published private(set) var permissionStatus: PushPermissionStatus = .notDetermined
    @Published private(set) var deviceTokenRegistered: Bool = false

    private var lastSyncedToken: String?

    private override init() {
        super.init()
    }

    func bootstrap() async {
        UNUserNotificationCenter.current().delegate = self
        await refreshPermissionStatus()
        if permissionStatus.canDeliver {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = PushPermissionStatus(from: settings.authorizationStatus)
    }

    /// Requests permission only if the user has not yet decided. Idempotent.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> PushPermissionStatus {
        await refreshPermissionStatus()
        guard permissionStatus == .notDetermined else { return permissionStatus }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await refreshPermissionStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            Log.push.error("Authorization request failed: \(error.localizedDescription, privacy: .public)")
        }
        return permissionStatus
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        guard !hex.isEmpty else { return }
        if hex == lastSyncedToken {
            deviceTokenRegistered = true
            return
        }
        lastSyncedToken = hex

        Task {
            await sendTokenToBackend(hex)
        }
    }

    func handleRegistrationFailure(_ error: Error) {
        deviceTokenRegistered = false
        Log.push.warning("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }

    /// Called from AppState.signOut() before the auth tokens are cleared so the
    /// backend can deactivate this device and stop sending pushes to it.
    func unregisterCurrentTokenIfPossible() async {
        guard let token = lastSyncedToken else { return }
        do {
            let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(
                .unregisterPushToken(UnregisterPushTokenBody(token: token))
            )
            lastSyncedToken = nil
            deviceTokenRegistered = false
        } catch {
            Log.push.warning("Push token deactivation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func sendTokenToBackend(_ token: String) async {
        let body = RegisterPushTokenBody(
            token: token,
            platform: AppConstants.Push.platform,
            environment: AppConstants.Push.environment
        )
        do {
            let _: APIVoidResponse = try await APIClient.shared.requestWithAutoRefresh(.registerPushToken(body))
            deviceTokenRegistered = true
        } catch {
            deviceTokenRegistered = false
            Log.push.warning("Push token registration failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo
        Task { @MainActor in
            NotificationRouter.route(payload: payload)
            completionHandler()
        }
    }
}
