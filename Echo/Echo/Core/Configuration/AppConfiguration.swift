import Foundation

/// Info.plist üzerinden gelen derleme yapılandırması. Sunucu adresi kodda uydurulmaz;
/// `ECHO_API_BASE_URL` build setting'inden gelir.
nonisolated struct AppConfiguration: Sendable {
    nonisolated enum LoadError: Error, Sendable {
        case missingAPIBaseURL
        case insecureAPIBaseURL
    }

    private nonisolated enum InfoKey: String {
        case apiBaseURL = "EchoAPIBaseURL"
        case subscriptionProductIDs = "EchoSubscriptionProductIDs"
    }

    private static let keychainServiceSuffix = ".session"

    let apiBaseURL: URL
    /// App Store Connect ürün kimlikleri. Sözleşmede katalog olmadığı için boş olabilir (plan B-4).
    let subscriptionProductIDs: [String]
    let keychainService: String

    static func load(from bundle: Bundle = .main) throws -> AppConfiguration {
        guard let rawURL = bundle.object(forInfoDictionaryKey: InfoKey.apiBaseURL.rawValue) as? String,
              let url = URL(string: rawURL) else {
            throw LoadError.missingAPIBaseURL
        }
        guard url.scheme == "https", url.host != nil else { throw LoadError.insecureAPIBaseURL }
        let productIDs = bundle.object(forInfoDictionaryKey: InfoKey.subscriptionProductIDs.rawValue) as? [String] ?? []
        let bundleIdentifier = bundle.bundleIdentifier ?? String(describing: AppConfiguration.self)
        return AppConfiguration(apiBaseURL: url,
                                subscriptionProductIDs: productIDs,
                                keychainService: bundleIdentifier + keychainServiceSuffix)
    }
}
