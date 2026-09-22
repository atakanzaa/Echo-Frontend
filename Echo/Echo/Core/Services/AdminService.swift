import Foundation
import EchoAdminAPI
import EchoAdminContract

/// Yönetim sözleşmesinin tipleri. Mobil sözleşmeyle ad çakıştığı için yalnız bu adla kullanılır.
typealias AdminAPI = EchoAdminContract.Components.Schemas

/// Yönetim paneli uçları (rules.md "Yönetim"). Değiştiren her çağrı gerekçe ister; sunucu denetim kaydına yazar.
nonisolated protocol AdminServicing: Sendable {
    func overview() async throws -> AdminAPI.AdminOverviewResponse
    func setControl(key: String, enabled: Bool, message: String?, reason: String) async throws -> [AdminAPI.AdminControlResponse]
    func blocks(autoOnly: Bool) async throws -> [AdminAPI.AccessBlockResponse]
    func createBlock(kind: String, value: String, duration: String, reason: String) async throws -> AdminAPI.AccessBlockResponse
    func confirmBlock(id: String, reason: String) async throws
    func liftBlock(id: String, reason: String) async throws
    func searchUsers(_ query: String) async throws -> [AdminAPI.AdminUserSummaryResponse]
    func user(id: String) async throws -> AdminAPI.AdminUserProfileResponse
    func ban(userID: String, duration: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse
    func unban(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse
    func signOut(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse
    func resetAllowance(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse
    func traffic(window: String) async throws -> AdminAPI.AdminTrafficResponse
    func aiUsage() async throws -> AdminAPI.AdminAiUsageResponse
    func switchProvider(_ provider: String) async throws
    func alerts() async throws -> [AdminAPI.AdminAlertResponse]
    func acknowledge(alertID: String) async throws
    func sendTestAlert() async throws -> AdminAPI.AdminAlertResponse
    func audit() async throws -> [AdminAPI.AdminAuditEntryResponse]
    func reports() async throws -> [AdminAPI.AdminModerationReportResponse]
    func resolveReport(id: String, action: String) async throws
    func errors() async throws -> [AdminAPI.AdminErrorResponse]
}

nonisolated struct LiveAdminService: AdminServicing {
    private let client: EchoAdminContract.Client

    init(stack: EchoAPIStack) {
        client = EchoAdminClient.make(connection: stack.connection)
    }

    func overview() async throws -> AdminAPI.AdminOverviewResponse {
        switch try await client.getAdminOverview(.init()) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func setControl(key: String, enabled: Bool, message: String?, reason: String) async throws -> [AdminAPI.AdminControlResponse] {
        let body = AdminAPI.AdminControlRequest(enabled: enabled, message: message, reason: reason)
        switch try await client.setAdminControl(.init(path: .init(key: key), body: .json(body))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func blocks(autoOnly: Bool) async throws -> [AdminAPI.AccessBlockResponse] {
        switch try await client.listAccessBlocks(.init(query: .init(auto: autoOnly))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func createBlock(kind: String, value: String, duration: String, reason: String) async throws -> AdminAPI.AccessBlockResponse {
        let body = AdminAPI.CreateAccessBlockRequest(kind: kind, value: value, duration: duration, reason: reason)
        switch try await client.createAccessBlock(.init(body: .json(body))) {
        case .created(let created): return try created.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func confirmBlock(id: String, reason: String) async throws {
        switch try await client.confirmAccessBlock(.init(path: .init(id: id), body: .json(.init(reason: reason)))) {
        case .noContent: return
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func liftBlock(id: String, reason: String) async throws {
        switch try await client.liftAccessBlock(.init(path: .init(id: id), body: .json(.init(reason: reason)))) {
        case .noContent: return
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func searchUsers(_ query: String) async throws -> [AdminAPI.AdminUserSummaryResponse] {
        switch try await client.searchAdminUsers(.init(query: .init(q: query))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func user(id: String) async throws -> AdminAPI.AdminUserProfileResponse {
        switch try await client.getAdminUserProfile(.init(path: .init(id: id))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func ban(userID: String, duration: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse {
        let body = AdminAPI.BanUserRequest(duration: duration, reason: reason)
        switch try await client.banUser(.init(path: .init(id: userID), body: .json(body))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func unban(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse {
        switch try await client.unbanUser(.init(path: .init(id: userID), body: .json(.init(reason: reason)))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func signOut(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse {
        switch try await client.signOutUser(.init(path: .init(id: userID), body: .json(.init(reason: reason)))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func resetAllowance(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse {
        switch try await client.resetUserAiAllowance(.init(path: .init(id: userID), body: .json(.init(reason: reason)))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func traffic(window: String) async throws -> AdminAPI.AdminTrafficResponse {
        switch try await client.getAdminTraffic(.init(query: .init(window: window))) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func aiUsage() async throws -> AdminAPI.AdminAiUsageResponse {
        switch try await client.getAdminAiUsage(.init()) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func switchProvider(_ provider: String) async throws {
        switch try await client.updateAdminAiConfig(.init(body: .json(.init(provider: provider)))) {
        case .ok: return
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func alerts() async throws -> [AdminAPI.AdminAlertResponse] {
        switch try await client.listAdminAlerts(.init()) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func acknowledge(alertID: String) async throws {
        switch try await client.acknowledgeAdminAlert(.init(path: .init(id: alertID))) {
        case .noContent: return
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func sendTestAlert() async throws -> AdminAPI.AdminAlertResponse {
        switch try await client.sendAdminTestAlert(.init()) {
        case .created(let created): return try created.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func audit() async throws -> [AdminAPI.AdminAuditEntryResponse] {
        switch try await client.listAdminAudit(.init()) {
        case .ok(let ok): return try ok.body.json
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func reports() async throws -> [AdminAPI.AdminModerationReportResponse] {
        switch try await client.listModerationReports(.init(query: .init(status: "open", size: 50))) {
        case .ok(let ok): return try ok.body.json.items
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func resolveReport(id: String, action: String) async throws {
        switch try await client.resolveModerationReport(.init(path: .init(reportId: id), body: .json(.init(action: action)))) {
        case .noContent: return
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    func errors() async throws -> [AdminAPI.AdminErrorResponse] {
        switch try await client.listMonitorErrors(.init(query: .init(scope: "last_24h", page: 0, size: 50))) {
        case .ok(let ok): return try ok.body.json.content
        case let .default(status, response): throw Self.error(status, try? response.body.applicationProblemJson)
        }
    }

    private static func error(_ status: Int, _ problem: AdminAPI.Problem?) -> AppError {
        guard let problem else { return .unexpectedResponse(status: status) }
        return .problem(EchoProblem(status: status, adminProblem: problem))
    }
}

extension EchoProblem {
    nonisolated init(status: Int, adminProblem problem: AdminAPI.Problem) {
        self.status = status
        code = problem.code.value1?.rawValue ?? problem.code.value2 ?? ""
        detail = problem.detail
        retryable = problem.retryable
        requestID = problem.requestId
        reasonCode = problem.reasonCode
        fieldErrors = problem.fieldErrors.map { FieldError(field: $0.field, code: $0.code) }
        resetsAt = nil
        offerUpgrade = false
    }
}
