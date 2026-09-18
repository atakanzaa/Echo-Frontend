import Foundation
import Observation

/// Sunucu yapılandırması ve sözlüğü. Dil değişince ikisi de yeniden okunur (rules.md §2, §11).
@Observable
@MainActor
final class AppConfigStore {
    private(set) var config: RemoteAppConfig?
    private(set) var vocabulary = ServerVocabulary()
    private(set) var error: AppError?
    private(set) var isLoading = false

    @ObservationIgnored private let service: any AppConfigServicing
    @ObservationIgnored private let appVersion: String?

    init(service: any AppConfigServicing, appVersion: String?) {
        self.service = service
        self.appVersion = appVersion
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let config = service.config(appVersion: appVersion)
            async let vocabulary = service.vocabulary()
            self.config = try await config
            self.vocabulary = try await vocabulary
        } catch {
            self.error = AppError.from(error)
        }
        isLoading = false
    }

    /// Sunucunun sürüm kararı; istemci sürüm karşılaştırması yapmaz.
    var requiresUpdate: Bool { config?.release.updateRequired == true }
    var recommendsUpdate: Bool { config?.release.updateRecommended == true }
}
