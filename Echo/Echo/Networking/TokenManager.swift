import Foundation
import Security

/// JWT token'larını Keychain'de güvenle saklar.
/// UserDefaults kullanılmaz — iCloud sync kapalı, cihaza özgü.
final class TokenManager {

    static let shared = TokenManager()
    private init() {}

    private let accessTokenService  = "com.echo.accessToken"
    private let refreshTokenService = "com.echo.refreshToken"

    // MARK: — Public API

    func saveAccessToken(_ token: String) throws {
        try save(token, service: accessTokenService)
    }

    func saveRefreshToken(_ token: String) throws {
        try save(token, service: refreshTokenService)
    }

    func accessToken() -> String? {
        load(service: accessTokenService)
    }

    func refreshToken() -> String? {
        load(service: refreshTokenService)
    }

    func clearAll() {
        delete(service: accessTokenService)
        delete(service: refreshTokenService)
    }

    var hasTokens: Bool {
        accessToken() != nil && refreshToken() != nil
    }

    // MARK: — Private Keychain Operations

    private func save(_ value: String, service: String) throws {
        let data = Data(value.utf8)

        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecValueData:       data,
            // iCloud'a yükleme, cihaza özgü, ilk unlock sonrası erişilebilir
            kSecAttrAccessible:  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Var olanı sil, sonra ekle
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw NetworkError.keychainError(status)
        }
    }

    private func load(service: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }

        return string
    }

    private func delete(service: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
