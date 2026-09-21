import Foundation
import OSLog
import EchoAPI
import OpenAPIRuntime

/// Sunucunun RFC 9457 hatası (rules.md §10). `detail` gösterime hazır metindir, `code` akış kararıdır.
nonisolated struct EchoProblem: Error, Sendable, Equatable {
    let status: Int
    /// Sabit makine değeri; bilinmeyen kod da korunur.
    let code: String
    let detail: String
    let retryable: Bool
    let requestID: String?
    let reasonCode: String?
    let fieldErrors: [FieldError]
    /// Yalnız `AI_QUOTA_EXHAUSTED`: hakkın yenileneceği an ve premium teklifinin gösterilip gösterilmeyeceği.
    let resetsAt: Date?
    let offerUpgrade: Bool

    nonisolated struct FieldError: Sendable, Equatable {
        let field: String
        let code: String
    }

    init(status: Int, problem: Components.Schemas.Problem) {
        self.status = status
        code = problem.code.value1?.rawValue ?? problem.code.value2 ?? ""
        detail = problem.detail
        retryable = problem.retryable
        requestID = problem.requestId
        reasonCode = problem.reasonCode
        fieldErrors = problem.fieldErrors.map { FieldError(field: $0.field, code: $0.code) }
        resetsAt = problem.resetsAt
        offerUpgrade = problem.offerUpgrade ?? false
    }

    var isAllowanceExhausted: Bool { code == "AI_QUOTA_EXHAUSTED" }

    /// Belirli alanın hatası; form ekranları bu kodu kendi metnine değil, sunucu metnine bağlar.
    func fieldError(_ field: String) -> FieldError? {
        fieldErrors.first { $0.field == field }
    }
}

/// Uygulamanın tek hata tipi. Ekranlar `message`'ı gösterir, akış kararını `problem?.code` ile verir.
nonisolated enum AppError: Error, Sendable {
    /// Sunucunun ürettiği hata.
    case problem(EchoProblem)
    /// Oturum geçersiz; giriş ekranına dönülür.
    case authenticationRequired
    /// Ağ veya sunucuya ulaşamama; oturum silinmez.
    case network
    /// Sözleşme dışı yanıt (proxy HTML'i, beklenmeyen durum kodu).
    case unexpectedResponse(status: Int?)

    var problem: EchoProblem? {
        if case let .problem(problem) = self { return problem }
        return nil
    }

    var isRetryable: Bool {
        switch self {
        case .problem(let problem): problem.retryable
        case .network: true
        case .authenticationRequired, .unexpectedResponse: false
        }
    }

    /// Kullanıcıya gösterilecek metin. Sunucu metni varsa aynen kullanılır; yoksa yerelleştirilmiş genel metin.
    var messageKey: String? {
        switch self {
        case .problem: nil
        case .authenticationRequired: "error.sessionExpired"
        case .network: "error.network"
        case .unexpectedResponse: "error.unexpected"
        }
    }

    var serverMessage: String? { problem?.detail }

    /// Sözleşmedeki `default` yanıtını uygulama hatasına çevirir.
    /// 401 burada oturum kaybı sayılmaz: giriş formundaki 401 form hatasıdır (rules.md §2).
    static func fromDefault(_ status: Int, _ problem: Components.Schemas.Problem?) -> AppError {
        guard let problem else { return .unexpectedResponse(status: status) }
        return .problem(EchoProblem(status: status, problem: problem))
    }

    /// Ekranda gösterilecek hata; iptal edilen iş (ekrandan çıkma, yenilemenin yerini alan yeni istek) hata değildir.
    static func displayable(_ error: any Error) -> AppError? {
        isCancellation(error) ? nil : from(error)
    }

    static func isCancellation(_ error: any Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        if let clientError = error as? ClientError { return isCancellation(clientError.underlyingError) }
        return false
    }

    /// Ağ katmanından gelen hatayı tek tipe indirger.
    static func from(_ error: any Error) -> AppError {
        #if DEBUG
        Logger(subsystem: "Yel.Echo", category: "errors").notice("AppError.from \(String(reflecting: error), privacy: .public)")
        #endif
        if let appError = error as? AppError { return appError }
        if let sessionError = error as? SessionError {

            switch sessionError {
            case .authenticationRequired, .sessionChanged: return .authenticationRequired
            default: return .unexpectedResponse(status: nil)
            }
        }
        if error is URLError { return .network }
        if let clientError = error as? ClientError {

            if clientError.underlyingError is URLError { return .network }
            if let sessionError = clientError.underlyingError as? SessionError {

                return sessionError == .authenticationRequired ? .authenticationRequired : .unexpectedResponse(status: nil)
            }
            return .unexpectedResponse(status: nil)
        }
        if error is CancellationError { return .network }
        return .unexpectedResponse(status: nil)
    }
}
