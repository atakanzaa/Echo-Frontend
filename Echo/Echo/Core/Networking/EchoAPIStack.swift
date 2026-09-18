import Foundation
import EchoAPI
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

/// Generated client, paylaşılan oturum ve kimlik doğrulamalı transport.
///
/// `EchoClient.make` ile aynı güvenlik ayarlarını kurar (yalnız HTTPS kökü, ephemeral oturum, cache/çerez yok, redirect yok,
/// ortak refresh). Paketten farkı iki sözleşme bulgusunun geçici çözümüdür (docs/ios-frontend-plan.md §6):
/// - C2: date-time alanları fraksiyonel saniyeli geldiği için toleranslı tarih çözümleyici.
/// - C1: generated `create` ses gövdesini üretmediği için multipart istek aynı `SessionTransport` üzerinden gönderilir.
/// Paket `configuration` kabul ettiğinde bu tip `EchoClient.make` çağrısına indirgenmelidir.
nonisolated struct EchoAPIStack: Sendable {
    let client: Client
    let session: SessionCoordinator
    let transport: SessionTransport
    let tokenStore: KeychainTokenStore
    let serverURL: URL

    private static let requestTimeout: TimeInterval = 30
    private static let resourceTimeout: TimeInterval = 90
    private static let maxRefreshResponseBytes = 1024 * 1024
    private static let refreshPath = "/api/v1/auth/refresh"
    private static let refreshOperationID = "refresh"

    static func make(serverURL: URL, keychainService: String) throws -> EchoAPIStack {
        guard serverURL.scheme == "https", serverURL.user == nil, serverURL.password == nil,
              serverURL.query == nil, serverURL.fragment == nil, serverURL.host != nil,
              serverURL.path.isEmpty || serverURL.path == "/" else {
            throw SessionError.insecureServerURL
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
        configuration.urlCache = nil
        configuration.httpShouldSetCookies = false
        let urlSession = URLSession(configuration: configuration, delegate: RedirectBlockingDelegate(), delegateQueue: nil)
        let base = URLSessionTransport(configuration: .init(session: urlSession))

        let tokenStore = KeychainTokenStore(service: keychainService)
        let session = SessionCoordinator(store: tokenStore) { refreshToken in
            let payload = try JSONEncoder().encode(Components.Schemas.RefreshTokenRequest(refreshToken: refreshToken))
            var request = HTTPRequest(method: .post, scheme: nil, authority: nil, path: refreshPath)
            request.headerFields[.contentType] = "application/json"
            let (response, body) = try await base.send(request, body: HTTPBody(payload), baseURL: serverURL, operationID: refreshOperationID)
            if response.status.code == 401 { throw SessionError.authenticationRequired }
            guard response.status.code == 200 else { throw RefreshFailure(status: response.status.code) }
            guard let body else { throw SessionError.invalidTokenResponse }
            let bytes = try await Data(collecting: body, upTo: maxRefreshResponseBytes)
            return try JSONDecoder().decode(SessionTokens.self, from: bytes)
        }

        let transport = SessionTransport(base: base, session: session)
        let client = Client(serverURL: serverURL,
                            configuration: .init(dateTranscoder: LenientISO8601DateTranscoder()),
                            transport: transport)
        return EchoAPIStack(client: client, session: session, transport: transport, tokenStore: tokenStore, serverURL: serverURL)
    }
}

/// Refresh uç noktasının 200 ve 401 dışındaki yanıtı. Geçici hatadır; Keychain oturumu silinmez.
nonisolated struct RefreshFailure: Error, Sendable {
    let status: Int
}

/// API yönlendirmeleri sözleşmenin parçası değil; kimlik bilgisi veya gövde başka adrese taşınmaz.
private nonisolated final class RedirectBlockingDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

/// Java `OffsetDateTime` biçimlerini (fraksiyonlu/fraksiyonsuz, saniyesiz) kabul eden tarih çözümleyici (C2).
nonisolated struct LenientISO8601DateTranscoder: DateTranscoder {
    func encode(_ date: Date) throws -> String {
        date.formatted(.iso8601)
    }

    func decode(_ dateString: String) throws -> Date {
        guard let date = BackendDate.instant(from: dateString) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unsupported ISO-8601 date-time"))
        }
        return date
    }
}
