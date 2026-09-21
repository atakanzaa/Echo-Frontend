import Foundation
import EchoAPI

/// Takvim ayı. `today` kullanıcının kendi günüdür; cihaz saatinden çıkarılmaz (rules.md §9).
nonisolated struct CalendarMonth: Sendable, Equatable {
    let year: Int
    let month: Int
    let today: LocalDay?
    let days: [Day]
    let averageMood: Double?
    let totalEntries: Int
    let activeDays: Int

    nonisolated struct Day: Sendable, Equatable, Identifiable {
        let day: Int
        let moodLabel: String?
        let entryID: String?
        let moodScore: Double?
        let moodCategory: EchoMoodCategory?
        let entryCount: Int
        let dominantEmotion: String?
        let hasCoachSession: Bool

        var id: Int { day }
    }

    init(dto: Components.Schemas.CalendarMonthResponse) {
        year = Int(dto.year)
        month = Int(dto.month)
        today = LocalDay(dto.today)
        days = dto.days.map {
            Day(day: Int($0.day),
                moodLabel: $0.moodLabel,
                entryID: $0.entryId,
                moodScore: $0.moodScore,
                moodCategory: $0.moodCategory.map { EchoMoodCategory(wire: $0.value1?.rawValue ?? $0.value2 ?? "") },
                entryCount: Int($0.entryCount),
                dominantEmotion: $0.dominantEmotion,
                hasCoachSession: $0.hasCoachSession)
        }
        averageMood = dto.monthSummary.averageMood
        totalEntries = Int(dto.monthSummary.totalEntries)
        activeDays = Int(dto.monthSummary.activeDays)
    }
}

/// Dönem özeti. Veri yoksa mood alanları null gelir; sıfır gösterilmez.
nonisolated struct PeriodSummary: Sendable, Equatable {
    let startDay: LocalDay?
    let endDay: LocalDay?
    let periodDays: Int
    let entryCount: Int
    let recordedDays: Int
    let coveragePercent: Double
    let averageMoodScore: Double?
    let highestMoodScore: Double?
    let lowestMoodScore: Double?
    let moodTrend: EchoMoodTrend
    let dominantTopics: [String]
    let topEmotions: [String]
    let energyDistribution: [EnergyCount]
    let moodCategoryDistribution: [CategoryShare]
    let bestDay: LocalDay?
    let worstDay: LocalDay?
    let narrativeSummary: String
    let dailyMoodScores: [DailyScore]

    nonisolated struct EnergyCount: Sendable, Equatable, Identifiable {
        let level: EchoEnergyLevel
        let count: Int
        var id: String { level.wire }
    }

    nonisolated struct CategoryShare: Sendable, Equatable, Identifiable {
        let category: EchoMoodCategory
        let count: Int
        let percent: Double
        var id: String { category.wire }
    }

    /// Dönemin her takvim günü için bir nokta; kayıtsız günde skor, etiket ve kategori null.
    nonisolated struct DailyScore: Sendable, Equatable, Identifiable {
        let day: LocalDay?
        let moodScore: Double?
        let moodLabel: String?
        let moodCategory: EchoMoodCategory?
        let entryCount: Int
        var id: String { day?.isoString ?? "" }
    }

    init(dto: Components.Schemas.SummaryResponse) {
        startDay = LocalDay(dto.startDate)
        endDay = LocalDay(dto.endDate)
        periodDays = Int(dto.periodDays)
        entryCount = Int(dto.entryCount)
        recordedDays = Int(dto.recordedDays)
        coveragePercent = dto.coveragePercent
        averageMoodScore = dto.averageMoodScore
        highestMoodScore = dto.highestMoodScore
        lowestMoodScore = dto.lowestMoodScore
        moodTrend = EchoMoodTrend(wire: dto.moodTrend.value1?.rawValue ?? dto.moodTrend.value2 ?? "")
        dominantTopics = dto.dominantTopics
        topEmotions = dto.topEmotions
        energyDistribution = dto.energyDistribution.map {
            EnergyCount(level: EchoEnergyLevel(wire: $0.level.value1?.rawValue ?? $0.level.value2 ?? ""), count: Int($0.count))
        }
        moodCategoryDistribution = dto.moodCategoryDistribution.map {
            CategoryShare(category: EchoMoodCategory(wire: $0.category.value1?.rawValue ?? $0.category.value2 ?? ""),
                          count: Int($0.count), percent: $0.percent)
        }
        bestDay = LocalDay(dto.bestDay)
        worstDay = LocalDay(dto.worstDay)
        narrativeSummary = dto.narrativeSummary
        dailyMoodScores = dto.dailyMoodScores.map {
            DailyScore(day: LocalDay($0.date), moodScore: $0.moodScore, moodLabel: $0.moodLabel,
                       moodCategory: $0.moodCategory.map { EchoMoodCategory(wire: $0.value1?.rawValue ?? $0.value2 ?? "") },
                       entryCount: Int($0.entryCount))
        }
    }
}

/// AI içgörü raporu. Haftalık seri boş günleri de içerir; `mood_score` null ise o gün kayıt yok.
nonisolated struct AIInsights: Sendable, Equatable {
    let period: Int
    let periodLabel: String
    let moodScore: Double?
    let moodTrend: EchoMoodTrend?
    let themes: [Theme]
    let suggestions: [Suggestion]
    let weeklyTrend: [DayPoint]
    let weeklyAverage: Double?
    let moodCategoryStats: [PeriodSummary.CategoryShare]
    let emotionalTrend: Double?
    let hasSufficientData: Bool
    let hasPreviousPeriodData: Bool
    let entryCount: Int
    let recordedDays: Int

    nonisolated struct Theme: Sendable, Equatable, Identifiable {
        let tag: String
        let count: Int
        let isTrending: Bool
        var id: String { tag }
    }

    nonisolated struct Suggestion: Sendable, Equatable, Identifiable {
        let title: String
        let body: String
        let icon: String?
        var id: String { title }
    }

    nonisolated struct DayPoint: Sendable, Equatable, Identifiable {
        let day: LocalDay?
        let moodScore: Double?
        let entryCount: Int
        var id: String { day?.isoString ?? UUID().uuidString }
    }

    init(dto: Components.Schemas.AIInsightsResponse) {
        period = Int(dto.period)
        periodLabel = dto.periodLabel
        moodScore = dto.moodScore
        moodTrend = dto.moodTrend.map { EchoMoodTrend(wire: $0.value1?.rawValue ?? $0.value2 ?? "") }
        themes = dto.themes.map { Theme(tag: $0.tag, count: Int($0.count), isTrending: $0.trending) }
        suggestions = dto.suggestions.map { Suggestion(title: $0.title, body: $0.body, icon: $0.icon) }
        weeklyTrend = dto.weeklyTrend.map { DayPoint(day: LocalDay($0.date), moodScore: $0.moodScore, entryCount: Int($0.entryCount)) }
        weeklyAverage = dto.weeklyAverage
        moodCategoryStats = dto.moodCategoryStats.map {
            PeriodSummary.CategoryShare(category: EchoMoodCategory(wire: $0.category.value1?.rawValue ?? $0.category.value2 ?? ""),
                                        count: Int($0.count), percent: $0.percent)
        }
        emotionalTrend = dto.emotionalTrend
        hasSufficientData = dto.hasSufficientData
        hasPreviousPeriodData = dto.hasPreviousPeriodData
        entryCount = Int(dto.entryCount)
        recordedDays = Int(dto.recordedDays)
    }
}

/// Dönem kilidi. Kilit kararı ve ilerleme sayıları sunucudan gelir.
nonisolated struct InsightEligibility: Sendable, Equatable {
    let periods: [Period]
    let defaultPeriod: Int
    let totalEntries: Int
    let totalDistinctDays: Int

    nonisolated struct Period: Sendable, Equatable, Identifiable {
        let days: Int
        let label: String
        let isUnlocked: Bool
        let requiredEntries: Int
        let currentEntries: Int
        let requiredDistinctDays: Int
        let currentDistinctDays: Int
        var id: Int { days }
    }

    init(dto: Components.Schemas.InsightsPeriodEligibilityResponse) {
        periods = dto.periods.map {
            Period(days: Int($0.days), label: $0.label, isUnlocked: $0.unlocked,
                   requiredEntries: Int($0.requiredEntries), currentEntries: Int($0.currentEntries),
                   requiredDistinctDays: Int($0.requiredDistinctDays), currentDistinctDays: Int($0.currentDistinctDays))
        }
        defaultPeriod = Int(dto.defaultPeriod)
        totalEntries = Int(dto.totalEntries)
        totalDistinctDays = Int(dto.totalDistinctDays)
    }
}

/// Detaylı istatistikler. Veri yetersizse alanlar null gelir; boş durum gösterilir.
nonisolated struct DetailedStats: Sendable, Equatable {
    let weeklyConsistency: [Int]
    let averageEntriesPerWeek: Double
    let mostActiveDay: String?
    let mostActiveHour: Int?
    let topTopicsThisMonth: [String]
    let topEmotionsThisMonth: [String]
    let moodTrendVsLastMonth: Double?
    let totalWords: Int
    let averageEntryLength: Int

    init(dto: Components.Schemas.DetailedStatsResponse) {
        weeklyConsistency = dto.weeklyConsistency.map(Int.init)
        averageEntriesPerWeek = dto.averageEntriesPerWeek
        mostActiveDay = dto.mostActiveDay.map { $0.value1?.rawValue ?? $0.value2 ?? "" }
        mostActiveHour = dto.mostActiveHour.map(Int.init)
        topTopicsThisMonth = dto.topTopicsThisMonth
        topEmotionsThisMonth = dto.topEmotionsThisMonth
        moodTrendVsLastMonth = dto.moodTrendVsLastMonth
        totalWords = Int(dto.totalWords)
        averageEntryLength = Int(dto.averageEntryLength)
    }
}

/// "Echo seni tanıyor" özeti; veri yoksa sunucu 204 döner ve bu model nil kalır.
nonisolated struct ProfileSummary: Sendable, Equatable {
    let userProfile: String?
    let emotionalPatterns: String?
    let valuesStrengths: String?
    let growthTrajectory: String?
    let weeklyDigest: String?
    let lastUpdated: Date?

    init(dto: Components.Schemas.ProfileSummaryResponse) {
        userProfile = dto.userProfile
        emotionalPatterns = dto.emotionalPatterns
        valuesStrengths = dto.valuesStrengths
        growthTrajectory = dto.growthTrajectory
        weeklyDigest = dto.weeklyDigest
        lastUpdated = dto.lastUpdated
    }
}

/// Başarımlar. Streak mesajı, sayaçlar ve rozet ilerlemesi sunucudan gelir (rules.md §9).
nonisolated struct Achievements: Sendable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    let totalWords: Int
    let insightScore: Double
    let streakMessage: String
    let earnedCount: Int
    let totalCount: Int
    let level: String
    let levelMessage: String
    let badges: [Badge]
    /// Sunucunun seçtiği sıradaki rozet; hepsi kazanıldıysa nil. İstemci seçim yapmaz.
    let nextBadge: Badge?

    nonisolated struct Badge: Sendable, Equatable, Identifiable {
        let key: String
        let title: String
        let emoji: String
        let description: String
        let criteriaDescription: String
        let isEarned: Bool
        let earnedAt: Date?
        let progress: Double
        let remaining: Int
        var id: String { key }
    }

    private static func badge(from dto: Components.Schemas.BadgeItem) -> Badge {
        Badge(key: dto.key.value1?.rawValue ?? dto.key.value2 ?? "",
              title: dto.title, emoji: dto.emoji, description: dto.description,
              criteriaDescription: dto.criteriaDescription, isEarned: dto.isEarned,
              earnedAt: dto.earnedAt, progress: dto.progress, remaining: Int(dto.remaining))
    }

    init(dto: Components.Schemas.AchievementsResponse) {
        currentStreak = Int(dto.currentStreak)
        longestStreak = Int(dto.longestStreak)
        totalEntries = Int(dto.totalEntries)
        totalWords = Int(dto.totalWords)
        insightScore = dto.insightScore
        streakMessage = dto.streakMessage
        earnedCount = Int(dto.earnedCount)
        totalCount = Int(dto.totalCount)
        level = dto.level
        levelMessage = dto.levelMessage
        badges = dto.badges.map(Achievements.badge(from:))
        nextBadge = dto.nextBadge.map(Achievements.badge(from:))
    }
}

nonisolated struct AchievementDetail: Sendable, Equatable {
    let badgeKey: String
    let title: String
    let emoji: String
    let description: String
    let criteriaDescription: String
    let isEarned: Bool
    let earnedAt: Date?
    let progress: Double
    let shareText: String

    init(dto: Components.Schemas.AchievementDetailResponse) {
        badgeKey = dto.badgeKey.value1?.rawValue ?? dto.badgeKey.value2 ?? ""
        title = dto.title
        emoji = dto.emoji
        description = dto.description
        criteriaDescription = dto.criteriaDescription
        isEarned = dto.isEarned
        earnedAt = dto.earnedAt
        progress = dto.progress
        shareText = dto.shareText
    }
}
