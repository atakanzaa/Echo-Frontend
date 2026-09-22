import Foundation
import Observation
import OSLog
import UIKit
import UserNotifications

/// Bildirime dokunulunca açılacak hedef; push içeriğindeki `target_type` ve `target_id`'den gelir.
nonisolated struct PushTarget: Sendable, Equatable {
    let type: EchoNotificationTarget
    let id: String?
}

/// APNs kaydı. İzin verilmişse cihaz her açılışta APNs'e kaydolur ve token oturum sahibine bağlanır;
/// çıkışta token bırakılır. Ortam Xcode derlemesinde sandbox, TestFlight ve App Store'da production'dır.
@Observable
@MainActor
final class PushRegistrar {
    static let shared = PushRegistrar()

    private(set) var token: String?
    /// Dokunulan bildirim; kabuk (ya da yönetim paneli) açıp temizler.
    var pendingTarget: PushTarget?

    @ObservationIgnored private var notifications: (any NotificationServicing)?
    @ObservationIgnored private var userID: String?
    @ObservationIgnored private var registered: (userID: String, token: String)?
    @ObservationIgnored private let log = Logger(subsystem: "Yel.Echo", category: "push")

    nonisolated static var environment: String {
        #if DEBUG
        "sandbox"
        #else
        "production"
        #endif
    }

    func attach(_ notifications: any NotificationServicing) {
        self.notifications = notifications
    }

    /// Oturum açıkken çağrılır; izin yoksa hiçbir şey sormaz. İzni ilgili ekranlar ister.
    func refresh(userID: String) async {
        self.userID = userID
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
        UIApplication.shared.registerForRemoteNotifications()
        await sync()
    }

    /// İzin ister ve verilirse kaydı tamamlar.
    func requestAuthorization(userID: String) async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        await refresh(userID: userID)
    }

    func received(deviceToken: Data) {
        token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await sync() }
    }

    func failed(_ error: any Error) {
        log.error("apns_registration_failed \(String(describing: error), privacy: .public)")
    }

    func signedOut() {
        userID = nil
        registered = nil
        pendingTarget = nil
    }

    func open(targetType: String?, targetID: String?) {
        guard let targetType else { return }
        pendingTarget = PushTarget(type: EchoNotificationTarget(wire: targetType), id: targetID)
    }

    private func sync() async {
        guard let token, let userID, let notifications else { return }
        if let registered, registered.userID == userID, registered.token == token { return }
        do {
            try await notifications.registerPushToken(token, environment: Self.environment)
            registered = (userID, token)
        } catch {
            log.error("push_token_register_failed \(String(describing: error), privacy: .public)")
        }
    }
}

/// UIKit'in APNs ve bildirim geri çağrıları. Ön plandaki bildirim de afiş olarak gösterilir.
final class EchoAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushRegistrar.shared.received(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        PushRegistrar.shared.failed(error)
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        let targetType = info["target_type"] as? String
        let targetID = info["target_id"] as? String
        await MainActor.run { PushRegistrar.shared.open(targetType: targetType, targetID: targetID) }
    }
}
