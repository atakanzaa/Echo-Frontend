import Foundation
import EchoAPI

/// Generated client + paylaşılan oturum. Güvenlik ayarları, ortak refresh, güvenli retry ve
/// `Accept-Language` paketin içindedir; uygulama kendi transport'unu kurmaz (rules.md §1).
nonisolated struct EchoAPIStack: Sendable {
    let client: Client
    let session: SessionCoordinator
    let tokenStore: KeychainTokenStore
    let serverURL: URL

    static func make(serverURL: URL,
                     keychainService: String,
                     language: @escaping @Sendable () -> String?) throws -> EchoAPIStack {
        let tokenStore = KeychainTokenStore(service: keychainService)
        let made = try EchoClient.make(serverURL: serverURL, tokenStore: tokenStore, language: language)
        return EchoAPIStack(client: made.client, session: made.session, tokenStore: tokenStore, serverURL: serverURL)
    }
}
