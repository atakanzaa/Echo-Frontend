import Foundation
import UserNotifications

enum PushPermissionStatus {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    init(from raw: UNAuthorizationStatus) {
        switch raw {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .ephemeral: self = .ephemeral
        @unknown default: self = .notDetermined
        }
    }

    var canDeliver: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined, .denied: return false
        }
    }
}
