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
    /// Bir istek `MAINTENANCE_MODE` döndüğünde yapılandırma yenilenene kadar bakım ekranı bununla açılır.
    private(set) var reportedMaintenance: String?
    /// Yalnız önizlemede dolar; canlı uygulamada duyurular her zaman `config`'ten okunur.
    private var previewNotices: [RemoteAppConfig.ServiceNotice] = []

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
            reportedMaintenance = nil
        } catch {
            self.error = AppError.displayable(error)
        }
        isLoading = false
    }

    #if DEBUG
    /// Yalnız önizleme: sözlük etiketlerini ağsız vermek için.
    func applyPreview(vocabulary: ServerVocabulary) {
        self.vocabulary = vocabulary
    }

    func applyPreview(notices: [RemoteAppConfig.ServiceNotice]) {
        previewNotices = notices
    }
    #endif

    /// Bakım metni; bakım yoksa nil. Sunucu bakımı kapatınca bir sonraki yüklemede kalkar.
    var maintenanceMessage: String? {
        notices.first { $0.key == "maintenance" }?.message ?? reportedMaintenance
    }

    /// Bakım dışındaki açık duyuru, örneğin `ai_paused` ya da `community_frozen`.
    func notice(_ key: String) -> RemoteAppConfig.ServiceNotice? {
        notices.first { $0.key == key }
    }

    private var notices: [RemoteAppConfig.ServiceNotice] { config?.serviceNotices ?? previewNotices }

    func reportMaintenance(_ message: String) {
        reportedMaintenance = message
    }

    /// Sunucunun sürüm kararı; istemci sürüm karşılaştırması yapmaz.
    var requiresUpdate: Bool { config?.release.updateRequired == true }
    var recommendsUpdate: Bool { config?.release.updateRecommended == true }
}
