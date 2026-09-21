import Foundation
import Observation

/// Kullanım hakkının son sunucu görüntüsü. Açılışta, öne gelişte, AI işlerinden sonra ve hak bitti hatasında yenilenir.
@Observable
@MainActor
final class UsageStore {
    private(set) var usage: AIUsage?

    @ObservationIgnored private let service: any UsageServicing
    @ObservationIgnored private var inFlight: Task<Void, Never>?

    init(service: any UsageServicing) {
        self.service = service
    }

    func refresh() async {
        if let inFlight { return await inFlight.value }
        let task = Task { [service] in
            if let fresh = try? await service.usage() { self.usage = fresh }
        }
        inFlight = task
        await task.value
        inFlight = nil
    }

    /// Hak bitti hatası geldiğinde durum sunucudan yeniden okunur; hata metni zaten sunucunun mesajıdır.
    func handle(_ error: AppError) {
        guard error.problem?.isAllowanceExhausted == true else { return }
        Task { await refresh() }
    }

    func clear() {
        usage = nil
    }

    #if DEBUG
    func applyPreview(_ usage: AIUsage) {
        self.usage = usage
    }
    #endif
}
