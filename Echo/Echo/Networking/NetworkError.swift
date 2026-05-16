import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case validation(String?)
    case serverError(Int, String?)
    case decodingError(Error)
    case keychainError(OSStatus)
    case noInternetConnection

    var errorDescription: String? {
        let turkish = Locale.autoupdatingCurrent.identifier.lowercased().hasPrefix("tr")

        switch self {
        case .invalidURL:
            return turkish ? "Geçersiz URL" : "Invalid URL."
        case .invalidResponse:
            return turkish ? "Geçersiz sunucu yanıtı" : "Invalid server response."
        case .unauthorized:
            return turkish ? "Oturum süreniz doldu. Lütfen yeniden giriş yapın." : "Your session expired. Please sign in again."
        case .forbidden:
            return turkish ? "Bu işlem için yetkiniz yok." : "You do not have permission to perform this action."
        case .notFound:
            return turkish ? "İstenen içerik bulunamadı." : "The requested content could not be found."
        case .timeout:
            return turkish ? "Bağlantı zaman aşımına uğradı. Tekrar deneyin." : "The request timed out. Please try again."
        case .validation(let message):
            return message ?? (turkish ? "Gönderilen bilgiler geçerli değil." : "The submitted information is invalid.")
        case .serverError(let statusCode, let message):
            if let message, !message.isEmpty {
                return message
            }
            if (500...599).contains(statusCode) {
                return turkish ? "Sunucu hatası. Lütfen daha sonra tekrar deneyin." : "Server error. Please try again later."
            }
            return turkish ? "Beklenmeyen bir hata oluştu. Tekrar deneyin." : "Something went wrong. Please try again."
        case .decodingError(let error):
            #if DEBUG
            return turkish ? "Veri ayrıştırma hatası: \(error.localizedDescription)" : "Decoding error: \(error.localizedDescription)"
            #else
            return turkish ? "Beklenmeyen bir hata oluştu. Tekrar deneyin." : "Something unexpected happened. Please try again."
            #endif
        case .keychainError(let status):
            return turkish ? "Güvenli depolama hatası: \(status)" : "Secure storage error: \(status)"
        case .noInternetConnection:
            return turkish ? "İnternet bağlantısı yok." : "No internet connection."
        }
    }
}
