import Foundation

enum AppConstants {
    enum API {
        #if DEBUG
        static let baseURL = "http://localhost:8080/api/v1"
        static let mediaBaseURL = "http://localhost:8080"
        #else
        static let baseURL = "https://echojournal.net/api/v1"
        static let mediaBaseURL = "https://echojournal.net"
        #endif

        static func mediaURL(for path: String?) -> URL? {
            guard let path, !path.isEmpty else { return nil }

            if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
                return absoluteURL
            }

            return URL(string: mediaBaseURL + path)
        }
    }

    enum Links {
        static let terms = URL(string: "https://echojournal.net/terms")!
        static let privacy = URL(string: "https://echojournal.net/privacy")!
        static let supportEmail = "support@echojournal.net"
    }

    enum Timeout {
        static let standard: TimeInterval = 15
        static let upload: TimeInterval = 120
        static let ai: TimeInterval = 60
    }

    enum Polling {
        static let journalStatusMaxAttempts = 30
        static let journalStatusDelayNanoseconds: UInt64 = 2_000_000_000
    }

    enum Recording {
        static let minimumDurationSeconds = 3
    }

    enum Pagination {
        static let defaultPageSize = 20
    }

    enum OAuth {
        static let googleClientId = "965240810843-ibiovp5mr1pr9vmnpqpjn11n1bnketf1.apps.googleusercontent.com"
    }

    enum AppInfo {
        static let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        static let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        static let shortVersionLabel = "v\(shortVersion)"
        static let fullVersionLabel = "\(shortVersion) (\(buildNumber))"
    }
}
