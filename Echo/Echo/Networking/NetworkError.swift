import Foundation
import Combine

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int, String?)
    case decodingError(Error)
    case keychainError(OSStatus)
    case noInternetConnection

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Geçersiz URL"
        case .invalidResponse:       return "Geçersiz sunucu yanıtı"
        case .unauthorized:          return "Oturum süreniz doldu. Lütfen yeniden giriş yapın."
        case .notFound:              return "İstenen kaynak bulunamadı"
        case .serverError(_, let m): return m ?? "Sunucu hatası"
        case .decodingError(let e):  return "Veri ayrıştırma hatası: \(e.localizedDescription)"
        case .keychainError(let s):  return "Güvenli depolama hatası: \(s)"
        case .noInternetConnection:  return "İnternet bağlantısı yok"
        }
    }
}
