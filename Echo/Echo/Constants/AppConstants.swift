import Foundation

enum AppConstants {
    enum Brand {
        static let companyDisplayName = "Echo"
        static let websiteURL: URL = {
            guard let url = URL(string: "https://echojournal.net") else {
                preconditionFailure("Invalid hardcoded website URL")
            }
            return url
        }()
    }

    enum API {
        #if DEBUG
        // LAN IP of the Mac running the backend — update when switching networks.
        // Get with: `ipconfig getifaddr en0` on the Mac.
        static let baseURL = "http://192.168.0.24:8080/api/v1"
        static let mediaBaseURL = "http://192.168.0.24:8080"
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

    enum AppInfo {
        static let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? Brand.companyDisplayName
        static let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        static let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.echojournal.echo"
        static let shortVersionLabel = "v\(shortVersion)"
        static let fullVersionLabel = "\(shortVersion) (\(buildNumber))"
        static let footerVersionLabel = "\(appDisplayName) \(fullVersionLabel)"
    }
}
