#if DEBUG
import OSLog
import SwiftUI
import EchoAdminContract

/// Yalnız DEBUG: `-EchoAdminPreview [-EchoRouteSweep]` paneli sahte veriyle, Face ID istemeden açar.
struct AdminPreviewHost: View {
    @State private var environment: AppEnvironment = {
        let environment = AppEnvironment.preview(.morning, admin: PreviewAdminService())
        environment.appLock.bypassesOwnerCheck = true
        return environment
    }()
    private let sweeps = ProcessInfo.processInfo.arguments.contains("-EchoRouteSweep")
    private let log = Logger(subsystem: "Yel.Echo", category: "sweep")

    var body: some View {
        AdminRootView(service: environment.admin, requiresUnlock: false)
            .environment(environment)
            .environment(environment.theme)
            .preferredColorScheme(.dark)
            .task { if sweeps { await sweep() } }
    }

    /// Bildirimden gelen uyarı akışı ve her sekme sırayla açılır; takılan adım logda görünür.
    private func sweep() async {
        try? await Task.sleep(for: .seconds(3))
        log.notice("SWEEP start admin.alert")
        environment.push.open(targetType: "admin_alert", targetID: PreviewAdminService.alertID)
        try? await Task.sleep(for: .seconds(2))
        log.notice("SWEEP ok admin.alert")
        log.notice("SWEEP done")
    }
}

nonisolated struct PreviewAdminService: AdminServicing {
    static let alertID = "0b6f3a52-1c7e-4a8e-9d51-6f2b8a9c1d11"
    private static let userID = "5a1d2c3b-4e5f-4a6b-8c7d-9e0f1a2b3c4d"
    private static let now = Date()

    func overview() async throws -> AdminAPI.AdminOverviewResponse {
        .init(system: .init(totalUsers: 412, newUsers24h: 9, newUsers7d: 58, activeToday: 137, totalEntries: 8_912, entries24h: 214,
                            stuckEntries: 0, failedEntries: 2, pushSent24h: 380, pushFailed24h: 3, pushSkipped24h: 12, pushPending: 0,
                            activePushTokens: 301, errors24h: 4, dlqUnresolved: 1, activeSubscriptions: 37, appVersion: "1.0.0",
                            dbReachable: true, generatedAt: Self.now),
              ai: .init(provider: "gemini", transcriptionProvider: "gemini", todayMicroUsd: 412_000, todayTry: 20.11,
                        monthMicroUsd: 9_300_000, monthTry: 453.84, monthBudgetTry: 1000, monthPercent: 45,
                        circuits: [.init(name: "gemini-analysis", state: "closed"), .init(name: "gemini-coach", state: "open")]),
              lastHour: .init(requests: 4_812, clientErrors: 61, serverErrors: 2, limited: 57),
              queueWaiting: 3,
              controls: controls(),
              unacknowledgedAlerts: 2,
              alerts: try await alerts(),
              autoBlocks: 1,
              generatedAt: Self.now)
    }

    private func controls() -> [AdminAPI.AdminControlResponse] {
        [.init(key: "maintenance", enabled: false, defaultMessage: "Kısa bir bakım yapıyoruz. Birazdan tekrar dene."),
         .init(key: "ai_paused", enabled: true, message: "Yapay zekâ analizi kısa süreliğine duraklatıldı.",
               defaultMessage: "Yapay zekâ özellikleri kısa süreliğine duraklatıldı.", updatedBy: "admin@echojournal.net",
               updatedAt: Self.now.addingTimeInterval(-900)),
         .init(key: "registrations_closed", enabled: false, defaultMessage: "Yeni hesap açılışı geçici olarak kapalı."),
         .init(key: "community_frozen", enabled: false, defaultMessage: "Topluluk şu an salt okunur.")]
    }

    func setControl(key: String, enabled: Bool, message: String?, reason: String) async throws -> [AdminAPI.AdminControlResponse] {
        controls().map { $0.key == key ? .init(key: key, enabled: enabled, message: message, defaultMessage: $0.defaultMessage,
                                                updatedBy: "admin@echojournal.net", updatedAt: .now) : $0 }
    }

    func blocks(autoOnly: Bool) async throws -> [AdminAPI.AccessBlockResponse] {
        let all: [AdminAPI.AccessBlockResponse] = [
            .init(id: "b1", kind: "ip", value: "203.0.113.50", reason: "automatic: login_failures", source: "auto", rule: "login_failures",
                  createdAt: Self.now.addingTimeInterval(-3_600), expiresAt: Self.now.addingTimeInterval(82_800)),
            .init(id: "b2", kind: "email_domain", value: "tempmail.example", reason: "Tek kullanımlık e-posta", source: "manual",
                  createdBy: "admin@echojournal.net", createdAt: Self.now.addingTimeInterval(-86_400 * 3))
        ]
        return autoOnly ? all.filter { $0.source == "auto" } : all
    }

    func createBlock(kind: String, value: String, duration: String, reason: String) async throws -> AdminAPI.AccessBlockResponse {
        .init(id: UUID().uuidString, kind: kind, value: value, reason: reason, source: "manual", createdAt: .now)
    }

    func confirmBlock(id: String, reason: String) async throws {}
    func liftBlock(id: String, reason: String) async throws {}

    func searchUsers(_ query: String) async throws -> [AdminAPI.AdminUserSummaryResponse] {
        [summary(), .init(id: UUID().uuidString, email: "deniz@example.com", displayName: "Deniz", role: "user", tier: "premium",
                          active: true, createdAt: Self.now.addingTimeInterval(-86_400 * 40))]
    }

    private func summary(bannedUntil: Date? = nil) -> AdminAPI.AdminUserSummaryResponse {
        .init(id: Self.userID, email: "flood@example.com", displayName: "Flood", role: "user", tier: "free", active: true,
              bannedUntil: bannedUntil, createdAt: Self.now.addingTimeInterval(-86_400 * 2))
    }

    func user(id: String) async throws -> AdminAPI.AdminUserProfileResponse { profile() }

    private func profile(bannedUntil: Date? = nil) -> AdminAPI.AdminUserProfileResponse {
        let state = AdminAPI.AiUsageState(value1: .warning)
        return .init(user: summary(bannedUntil: bannedUntil), banReason: bannedUntil == nil ? nil : "spam", entryCount: 31, postCount: 12,
                     reportsAgainst: 4, lastSessionAt: Self.now.addingTimeInterval(-300),
                     aiUsage: .init(tier: .init(value1: .free), state: state, usedPercent: 86, resetsAt: Self.now.addingTimeInterval(20_000),
                                    windows: [.init(scope: .init(value1: .day), usedPercent: 86, resetsAt: Self.now.addingTimeInterval(20_000),
                                                    state: state)],
                                    offerUpgrade: true, allowedActions: []),
                     addresses: [.init(ip: "198.51.100.23", firstSeen: Self.now.addingTimeInterval(-86_400), lastSeen: Self.now.addingTimeInterval(-300),
                                       hits: 412, blocked: false),
                                 .init(ip: "203.0.113.50", firstSeen: Self.now.addingTimeInterval(-7_200), lastSeen: Self.now.addingTimeInterval(-3_700),
                                       hits: 57, blocked: true)])
    }

    func ban(userID: String, duration: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse {
        profile(bannedUntil: Self.now.addingTimeInterval(86_400))
    }

    func unban(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse { profile() }
    func signOut(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse { profile() }
    func resetAllowance(userID: String, reason: String) async throws -> AdminAPI.AdminUserProfileResponse { profile() }

    func traffic(window: String) async throws -> AdminAPI.AdminTrafficResponse {
        let hourly = window == "24h"
        let step: TimeInterval = hourly ? 3_600 : 60
        let span = hourly ? 24 : 60
        let series = (0..<span).map { index -> AdminAPI.AdminTrafficSlot in
            let requests = Int64(40 + (index * 37) % 90)
            return .init(start: Self.now.addingTimeInterval(-step * Double(span - index)), requests: requests,
                         clientErrors: requests / 20, serverErrors: index % 17 == 0 ? 2 : 0, limited: index > span - 6 ? 12 : 0)
        }
        return .init(window: window, series: series,
                     endpoints: [.init(endpoint: "GET /api/v1/journal/entries", requests: 1_204, clientErrors: 3, serverErrors: 0, limited: 0),
                                 .init(endpoint: "POST /api/v1/auth/login", requests: 388, clientErrors: 301, serverErrors: 0, limited: 57),
                                 .init(endpoint: "POST /api/v1/coach/sessions/{id}/messages", requests: 211, clientErrors: 0, serverErrors: 2, limited: 0)],
                     callers: [.init(kind: "ip", value: "203.0.113.50", requests: 402, clientErrors: 301, serverErrors: 0, limited: 57, blocked: true),
                               .init(kind: "user", value: Self.userID, userId: Self.userID, email: "flood@example.com", requests: 390,
                                     clientErrors: 2, serverErrors: 0, limited: 12, blocked: false),
                               .init(kind: "ip", value: "198.51.100.77", requests: 96, clientErrors: 40, serverErrors: 0, limited: 0, blocked: false)])
    }

    func aiUsage() async throws -> AdminAPI.AdminAiUsageResponse {
        .init(month: "2026-09-01", spentMicroUsd: 9_300_000, spentTry: 453.84, budgetTry: 1000, usedPercent: 45,
              operations: [.init(operation: "journal_analysis", calls: 2_310, inputTokens: 4_100_000, outputTokens: 900_000,
                                 thinkingTokens: 300_000, costMicroUsd: 6_400_000),
                           .init(operation: "coach", calls: 880, inputTokens: 1_900_000, outputTokens: 400_000, thinkingTokens: 0,
                                 costMicroUsd: 2_900_000)],
              tiers: [], topUsers: [.init(userId: Self.userID, tier: "free", calls: 310, costMicroUsd: 1_200_000)])
    }

    func switchProvider(_ provider: String) async throws {}

    func alerts() async throws -> [AdminAPI.AdminAlertResponse] {
        [.init(id: Self.alertID, key: "auto_block:ip:203.0.113.50", severity: "warning", title: "Şifre deneme saldırısı engellendi",
               body: "203.0.113.50 adresinden 10 dakikada 20 başarısız giriş denemesi. Adres 24 saat engellendi.", target: "blocks",
               createdAt: Self.now.addingTimeInterval(-600), pushSentAt: Self.now.addingTimeInterval(-600)),
         .init(id: "a2", key: "circuit:gemini-coach", severity: "critical", title: "Yapay zeka sağlayıcısı yanıt vermiyor",
               body: "gemini-coach devre kesicisi açık; çağrılar geçici olarak durduruldu.", target: "ai",
               createdAt: Self.now.addingTimeInterval(-1_800), pushSentAt: Self.now.addingTimeInterval(-1_800)),
         .init(id: "a3", key: "ai_share:x", severity: "info", title: "Tek hesap AI harcamasının büyük kısmını yapıyor",
               body: "flood@example.com bugünkü AI harcamasının yüzde 31 kadarını tek başına yaptı.", target: "users/\(Self.userID)",
               createdAt: Self.now.addingTimeInterval(-7_200), emailSentAt: Self.now.addingTimeInterval(-7_080),
               acknowledgedAt: Self.now.addingTimeInterval(-7_000))]
    }

    func acknowledge(alertID: String) async throws {}

    func sendTestAlert() async throws -> AdminAPI.AdminAlertResponse {
        .init(id: UUID().uuidString, key: "test", severity: "info", title: "Test uyarısı", body: "Bu bir test uyarısı.", createdAt: .now)
    }

    func audit() async throws -> [AdminAPI.AdminAuditEntryResponse] {
        [.init(id: "e1", action: "control_on", targetType: "control", targetId: "ai_paused", reason: "Sağlayıcı faturası",
               adminEmail: "admin@echojournal.net", createdAt: Self.now.addingTimeInterval(-900)),
         .init(id: "e2", action: "block_auto", targetType: "ip", targetId: "203.0.113.50", reason: "automatic: login_failures",
               createdAt: Self.now.addingTimeInterval(-3_600))]
    }

    func reports() async throws -> [AdminAPI.AdminModerationReportResponse] {
        [.init(id: "r1", targetType: "post", postId: "p1", reason: "spam", details: "Aynı bağlantıyı her yere yapıştırıyor", status: "open",
               targetExcerpt: "Ücretsiz takipçi için bu bağlantıya tıkla…", openReporterCount: 3, createdAt: Self.now.addingTimeInterval(-2_400))]
    }

    func resolveReport(id: String, action: String) async throws {}

    func errors() async throws -> [AdminAPI.AdminErrorResponse] {
        [.init(id: "x1", occurredAt: Self.now.addingTimeInterval(-1_200), httpStatus: 500, errorCode: "INTERNAL_ERROR",
               exceptionClass: "TimeoutException", shortMessage: "Gemini read timed out", path: "/api/v1/coach/sessions/{id}/messages",
               method: "POST", severity: "ERROR")]
    }
}
#endif
