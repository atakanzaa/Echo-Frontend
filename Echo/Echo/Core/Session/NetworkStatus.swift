import Foundation
import Network
import Observation

/// Cihazın bağlantı durumu. Yalnız "çevrimdışısın" şeridini göstermek için; veri kararı vermez.
@Observable
@MainActor
final class NetworkStatus {
    private(set) var isOnline = true

    @ObservationIgnored private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "echo.network-status"))
    }

    deinit {
        monitor.cancel()
    }
}
