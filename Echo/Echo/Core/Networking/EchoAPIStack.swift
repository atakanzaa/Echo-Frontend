import Foundation
import EchoAPI

/// Generated client + paylaşılan oturum. Güvenlik ayarları, ortak refresh, güvenli retry ve
/// `Accept-Language` paketin içindedir; uygulama kendi transport'unu kurmaz (rules.md §1).
nonisolated struct EchoAPIStack: Sendable {
    let client: Client
    let session: SessionCoordinator
    let tokenStore: KeychainTokenStore
    let serverURL: URL
    /// Yönetim paneli istemcisi aynı oturum ve transport'la kurulur.
    let connection: EchoConnection

    static func make(serverURL: URL,
                     keychainService: String,
                     language: @escaping @Sendable () -> String?) throws -> EchoAPIStack {
        let tokenStore = KeychainTokenStore(service: keychainService)
        let connection = try EchoClient.connect(serverURL: serverURL, tokenStore: tokenStore, language: language)
        let client = Client(serverURL: serverURL, configuration: EchoClient.defaultConfiguration, transport: connection.transport)
        return EchoAPIStack(client: client, session: connection.session, tokenStore: tokenStore, serverURL: serverURL,
                            connection: connection)
    }
}
