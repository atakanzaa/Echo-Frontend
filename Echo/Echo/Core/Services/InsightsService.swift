import Foundation
import EchoAPI

/// Takvim, özet, AI içgörü, istatistik ve başarım uçları (rules.md §9).
nonisolated protocol InsightsServicing: Sendable {
    func calendar(year: Int, month: Int) async throws -> CalendarMonth
    func summary(periodDays: Int, endDay: LocalDay?) async throws -> PeriodSummary
    func insights(periodDays: Int) async throws -> AIInsights
    func eligibility() async throws -> InsightEligibility
    func detailedStats() async throws -> DetailedStats
    /// Veri yoksa sunucu 204 döner; bu durumda nil.
    func profileSummary() async throws -> ProfileSummary?
    func achievements() async throws -> Achievements
    func achievementDetail(badgeKey: String) async throws -> AchievementDetail
}

nonisolated struct LiveInsightsService: InsightsServicing {
    let stack: EchoAPIStack

    func calendar(year: Int, month: Int) async throws -> CalendarMonth {
        switch try await stack.client.getCalendarMonth(.init(query: .init(year: Int32(year), month: Int32(month)))) {
        case .ok(let ok): return CalendarMonth(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func summary(periodDays: Int, endDay: LocalDay?) async throws -> PeriodSummary {
        // Sözleşme dönem değerlerini sabit bir sözlükle sınırlar; bilinmeyen değer istenmez.
        guard let period = Operations.GetPeriodSummary.Input.Query.PeriodPayload(rawValue: periodDays) else {
            throw AppError.unexpectedResponse(status: nil)
        }
        switch try await stack.client.getPeriodSummary(.init(query: .init(period: period, endDate: endDay?.isoString))) {
        case .ok(let ok): return PeriodSummary(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func insights(periodDays: Int) async throws -> AIInsights {
        guard let period = Operations.GetAIInsights.Input.Query.PeriodPayload(rawValue: periodDays) else {
            throw AppError.unexpectedResponse(status: nil)
        }
        switch try await stack.client.getAIInsights(.init(query: .init(period: period))) {
        case .ok(let ok): return AIInsights(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func eligibility() async throws -> InsightEligibility {
        switch try await stack.client.getInsightEligibility(.init()) {
        case .ok(let ok): return InsightEligibility(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func detailedStats() async throws -> DetailedStats {
        switch try await stack.client.getDetailedUserStats(.init()) {
        case .ok(let ok): return DetailedStats(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func profileSummary() async throws -> ProfileSummary? {
        switch try await stack.client.getProfileSummary(.init()) {
        case .ok(let ok): return ProfileSummary(dto: try ok.body.json)
        case .noContent: return nil
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func achievements() async throws -> Achievements {
        switch try await stack.client.getAchievements(.init()) {
        case .ok(let ok): return Achievements(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }

    func achievementDetail(badgeKey: String) async throws -> AchievementDetail {
        switch try await stack.client.getAchievementDetail(.init(path: .init(badgeKey: badgeKey))) {
        case .ok(let ok): return AchievementDetail(dto: try ok.body.json)
        case let .`default`(status, response): throw AppError.fromDefault(status, try? response.body.applicationProblemJson)
        }
    }
}
