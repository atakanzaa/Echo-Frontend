import Foundation
import EchoAPI

/// AI kullanım hakkı (rules.md §8). Yüzde, durum ve yenilenme anı sunucu kararıdır; uygulama yalnız biçimlendirir.
nonisolated struct AIUsage: Sendable, Equatable {
    nonisolated enum State: Sendable, Equatable {
        case ok, warning, exhausted
        case unknown(String)

        init(wire: String) {
            switch wire {
            case "ok": self = .ok
            case "warning": self = .warning
            case "exhausted": self = .exhausted
            default: self = .unknown(wire)
            }
        }
    }

    nonisolated enum Scope: Sendable, Equatable {
        case day, month, service
        case unknown(String)

        init(wire: String) {
            switch wire {
            case "day": self = .day
            case "month": self = .month
            case "service": self = .service
            default: self = .unknown(wire)
            }
        }
    }

    nonisolated struct Window: Sendable, Equatable, Identifiable {
        let scope: Scope
        let usedPercent: Int
        let resetsAt: Date
        let state: State
        var id: String { "\(scope)" }
    }

    let isPremium: Bool
    let state: State
    let usedPercent: Int
    let resetsAt: Date
    let windows: [Window]
    let message: String?
    let offerUpgrade: Bool
    let allowedActions: [String]

    /// Koç ve analiz gibi AI işleri şu an açık mı; karar sunucunun `allowed_actions` listesidir.
    var canUseAI: Bool { allowedActions.contains("send_coach_message") }

    init(isPremium: Bool, state: State, usedPercent: Int, resetsAt: Date, windows: [Window],
         message: String?, offerUpgrade: Bool, allowedActions: [String]) {
        self.isPremium = isPremium
        self.state = state
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
        self.windows = windows
        self.message = message
        self.offerUpgrade = offerUpgrade
        self.allowedActions = allowedActions
    }

    init(dto: Components.Schemas.AiUsageResponse) {
        isPremium = (dto.tier.value1?.rawValue ?? dto.tier.value2) == "premium"
        state = State(wire: dto.state.value1?.rawValue ?? dto.state.value2 ?? "")
        usedPercent = Int(dto.usedPercent)
        resetsAt = dto.resetsAt
        windows = dto.windows.map {
            Window(scope: Scope(wire: $0.scope.value1?.rawValue ?? $0.scope.value2 ?? ""),
                   usedPercent: Int($0.usedPercent), resetsAt: $0.resetsAt,
                   state: State(wire: $0.state.value1?.rawValue ?? $0.state.value2 ?? ""))
        }
        message = dto.message
        offerUpgrade = dto.offerUpgrade
        allowedActions = dto.allowedActions.map { $0.value1?.rawValue ?? $0.value2 ?? "" }
    }
}
