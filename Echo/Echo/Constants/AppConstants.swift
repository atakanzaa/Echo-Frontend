import Foundation

enum AppConstants {
    enum Brand {
        static let companyDisplayName = "Echo"
        static let websiteURL = URL(string: "https://echojournal.net")!
    }

    enum API {
        #if DEBUG
        // Debug builds talk to the production backend (api.echojournal.net → 91.99.54.30).
        // To test against a local Mac backend instead, swap these for the LAN IP:
        //   static let baseURL = "http://<ipconfig getifaddr en0>:8080/api/v1"
        //   static let mediaBaseURL = "http://<ipconfig getifaddr en0>:8080"
        static let baseURL = "https://api.echojournal.net/api/v1"
        static let mediaBaseURL = "https://api.echojournal.net"
        #else
        static let baseURL = "https://api.echojournal.net/api/v1"
        static let mediaBaseURL = "https://api.echojournal.net"
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
        static let website = Brand.websiteURL
        static let supportEmail = "support@echojournal.net"
        static let appStoreID: String? = nil

        static var appStoreReviewURL: URL? {
            guard let appStoreID else { return nil }
            return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
        }
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

    enum Push {
        static let platform = "IOS"

        // The aps-environment entitlement determines which APNs server iOS
        // talks to. Debug builds register through sandbox, release builds
        // (TestFlight + App Store) through production.
        #if DEBUG
        static let environment = "DEVELOPMENT"
        #else
        static let environment = "PRODUCTION"
        #endif
    }

    enum AppInfo {
        static let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? Brand.companyDisplayName
        static let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        static let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Yel.Echo"
        static let shortVersionLabel = "v\(shortVersion)"
        static let fullVersionLabel = "\(shortVersion) (\(buildNumber))"
        static let footerVersionLabel = "\(appDisplayName) \(fullVersionLabel)"
    }
}
