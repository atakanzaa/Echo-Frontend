import Foundation
import EchoAPI
import Observation

/// Oturum durumu ve kullanıcı bilgisi. Refresh 401 oturumu kapatır; ağ hatası kapatmaz (rules.md §2).
@Observable
@MainActor
final class SessionStore {
    nonisolated enum State: Sendable, Equatable {
        case restoring
        case signedOut
        case signedIn(AuthenticatedUser)

        var user: AuthenticatedUser? {
            if case let .signedIn(user) = self { return user }
            return nil
        }
    }

    private(set) var state: State = .restoring
    /// Açılışta oturum geri yüklenemediyse (ağ/sunucu) gösterilir; oturum silinmez.
    private(set) var restoreError: AppError?
    private(set) var isWorking = false
    /// Oturum sunucu kararıyla bittiyse (hesap ya da adres engeli) karşılama ekranında gösterilen sunucu metni.
    private(set) var endedMessage: String?

    @ObservationIgnored private let auth: any AuthServicing
    @ObservationIgnored private let notifications: any NotificationServicing
    @ObservationIgnored private let tokenStore: KeychainTokenStore

    init(auth: any AuthServicing, notifications: any NotificationServicing, tokenStore: KeychainTokenStore) {
        self.auth = auth
        self.notifications = notifications
        self.tokenStore = tokenStore
    }

    /// Keychain'de oturum varsa kullanıcıyı sunucudan okur.
    func restore() async {
        restoreError = nil
        guard (try? tokenStore.read()) ?? nil != nil else {
            state = .signedOut
            return
        }
        state = .restoring
        do {
            state = .signedIn(try await auth.currentUser())
        } catch {
            let appError = AppError.from(error)
            if case .authenticationRequired = appError {

                try? await auth.signOut()
                state = .signedOut
            } else if let problem = appError.problem, problem.status == 401 {

                try? await auth.signOut()
                state = .signedOut
            } else {
                // Geçici hata: oturum korunur, kullanıcıya "tekrar dene" gösterilir.
                restoreError = appError
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await perform { try await auth.signIn(email: email, password: password) }
    }

    func register(email: String, password: String, displayName: String, timezone: String, language: AppLanguage) async throws {
        try await perform {
            try await auth.register(email: email, password: password, displayName: displayName,
                                    timezone: timezone, language: language)
        }
    }

    func signInWithGoogle(idToken: String, timezone: String, language: AppLanguage) async throws {
        try await perform { try await auth.signInWithGoogle(idToken: idToken, timezone: timezone, language: language) }
    }

    func signInWithApple(identityToken: String, rawNonce: String, displayName: String?, timezone: String, language: AppLanguage) async throws {
        try await perform {
            try await auth.signInWithApple(identityToken: identityToken, rawNonce: rawNonce,
                                           displayName: displayName, timezone: timezone, language: language)
        }
    }

    /// Sayaçlar ve `recorded_today` sunucudan yeniden okunur; istemci güncellemez.
    func refreshUser() async {
        guard state.user != nil else { return }
        if let user = try? await auth.currentUser() { state = .signedIn(user) }
    }

    func apply(_ user: AuthenticatedUser) {
        state = .signedIn(user)
    }

    #if DEBUG
    /// Yalnız önizleme: sunucunun bitirdiği oturumu ağsız göstermek için.
    func applyPreview(endedMessage: String) {
        self.endedMessage = endedMessage
        state = .signedOut
    }
    #endif

    /// Çıkışta önce cihazın push token sahipliği bırakılır, sonra sunucu oturumu kapatılır.
    func signOut(pushToken: String? = nil) async {
        endedMessage = nil
        isWorking = true
        if let pushToken { try? await notifications.unregisterPushToken(pushToken) }
        try? await auth.signOut()
        isWorking = false
        state = .signedOut
    }

    /// Sunucu hesabı ya da adresi engellediğinde: yerel oturum kapanır, cihazdaki gönderilmemiş kayıtlar korunur.
    func end(message: String) async {
        guard state.user != nil else { return }
        try? await auth.signOut()
        endedMessage = message
        state = .signedOut
    }

    private func perform(_ work: () async throws -> AuthenticatedUser) async throws {
        isWorking = true
        defer { isWorking = false }
        do {
            state = .signedIn(try await work())
            endedMessage = nil
        } catch {
            throw AppError.from(error)
        }
    }
}
