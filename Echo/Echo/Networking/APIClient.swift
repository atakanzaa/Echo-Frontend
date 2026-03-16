import Foundation
import Combine

/// Merkezi HTTP istemci. Tüm API çağrıları buradan geçer.
/// - 401 gelince otomatik token yeniler
/// - Hata yanıtlarını `NetworkError`'a çevirir
/// - JSON encoding: camelCase → snake_case; decoding: snake_case → camelCase
@MainActor
final class APIClient {

    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: — Public API

    func request<T: Decodable>(_ endpoint: APIRouter) async throws -> T {
        let urlRequest = try buildRequest(endpoint)
        return try await execute(urlRequest, endpoint: endpoint)
    }

    /// Multipart upload için özel metod
    func upload<T: Decodable>(_ endpoint: APIRouter) async throws -> T {
        let boundary = UUID().uuidString
        var urlRequest = try endpoint.buildMultipartRequest(boundary: boundary)
        attachToken(&urlRequest)
        return try await executeRaw(urlRequest, endpoint: endpoint)
    }

    // MARK: — Private

    private func buildRequest(_ endpoint: APIRouter) throws -> URLRequest {
        var request = try endpoint.asURLRequest()
        attachToken(&request)
        return request
    }

    private func attachToken(_ request: inout URLRequest) {
        if let token = TokenManager.shared.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func execute<T: Decodable>(_ request: URLRequest,
                                       endpoint: APIRouter) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            return try handleResponse(data: data, response: response,
                                      request: request, endpoint: endpoint)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.noInternetConnection
        }
    }

    private func executeRaw<T: Decodable>(_ request: URLRequest,
                                          endpoint: APIRouter) async throws -> T {
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data: data, response: response,
                                  request: request, endpoint: endpoint)
    }

    private func handleResponse<T: Decodable>(data: Data,
                                              response: URLResponse,
                                              request: URLRequest,
                                              endpoint: APIRouter) throws -> T {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            do {
                let body = data.isEmpty ? Data("{}".utf8) : data
                return try APIClient.decoder.decode(T.self, from: body)
            } catch {
                throw NetworkError.decodingError(error)
            }

        case 401:
            // Body'de backend mesajı varsa onu kullan (örn. "E-posta veya şifre hatalı")
            if let errResp = try? APIClient.decoder.decode(APIErrorResponse.self, from: data),
               errResp.code == "INVALID_CREDENTIALS" {
                throw NetworkError.serverError(401, errResp.message)
            }
            throw NetworkError.unauthorized

        case 404:
            throw NetworkError.notFound

        default:
            let message = (try? APIClient.decoder.decode(APIErrorResponse.self, from: data))?.message
            throw NetworkError.serverError(http.statusCode, message)
        }
    }
}

// MARK: — Token Refresh Extension

extension APIClient {

    /// 401 aldığında refresh token ile yeni access token alır.
    /// Başarılıysa isteği tekrar gönderir. Başarısızsa signOut yapar.
    func requestWithAutoRefresh<T: Decodable>(_ endpoint: APIRouter) async throws -> T {
        do {
            return try await request(endpoint)
        } catch NetworkError.unauthorized {
            try await refreshTokens()
            return try await request(endpoint)
        }
    }

    func uploadWithAutoRefresh<T: Decodable>(_ endpoint: APIRouter) async throws -> T {
        do {
            return try await upload(endpoint)
        } catch NetworkError.unauthorized {
            try await refreshTokens()
            return try await upload(endpoint)
        }
    }

    private func refreshTokens() async throws {
        guard let rawRefresh = TokenManager.shared.refreshToken() else {
            await AppState.shared.signOut()
            throw NetworkError.unauthorized
        }

        do {
            let body = RefreshBody(refreshToken: rawRefresh)
            let response: APIAuthResponse = try await request(.refreshToken(body))
            try TokenManager.shared.saveAccessToken(response.accessToken)
            try TokenManager.shared.saveRefreshToken(response.refreshToken)
        } catch {
            await AppState.shared.signOut()
            throw NetworkError.unauthorized
        }
    }
}
