import Foundation

// MARK: — Auth

struct APIAuthResponse: Decodable {
    let accessToken:  String
    let refreshToken: String
    let expiresIn:    Int
    let user:         APIUser
}

struct APIUser: Decodable {
    let id:             String
    let email:          String
    let displayName:    String?
    let timezone:       String
    let currentStreak:  Int
    let longestStreak:  Int
    let totalEntries:   Int
    let moodScoreAvg:   Double
}

// MARK: — Journal

struct APIJournalEntry: Decodable {
    let id:                   String
    let recordedAt:           String
    let entryDate:            String
    let audioUrl:             String?
    let audioDurationSeconds: Int?
    let transcript:           String?
    let status:               String
    let errorMessage:         String?
    let analysis:             APIAnalysisResult?
    let createdAt:            String?

    var entryStatus: EntryStatus { EntryStatus(rawBackend: status) }
}

struct APIAnalysisResult: Decodable {
    let summary:            String?
    let moodScore:          Double?
    let moodLabel:          String?
    let moodCategory:       String?   // "STRESS" | "NEUTRAL" | "CALM" | "MOTIVATED"
    let topics:             [String]?
    let reflectiveQuestion: String?
    let keyEmotions:        [String]?
    let energyLevel:        String?
    // Extended analysis fields — optional (backwards compatible)
    let goals:              [APIGoalPreview]?
    let insights:           [String]?
    let memoryWorthy:       Bool?

    var resolvedMoodCategory: MoodCategory? {
        moodCategory.map(MoodCategory.init(rawBackend:))
    }
}

/// Analizden çıkarılan hedef önizlemesi (goals endpoint'indeki tam APIGoal'dan farklı)
struct APIGoalPreview: Decodable {
    let title:     String
    let timeframe: String?
    let goalType:  String?
    enum CodingKeys: String, CodingKey {
        case title, timeframe
        case goalType = "goal_type"
    }
}

struct APIEntryStatus: Decodable {
    let id:           String
    let status:       String
    let errorMessage: String?

    var entryStatus: EntryStatus { EntryStatus(rawBackend: status) }
}

// MARK: — Summary

struct APISummaryResponse: Decodable {
    let startDate:           String
    let endDate:             String
    let periodDays:          Int
    let recordedDays:        Int
    let coveragePercent:     Double
    let averageMoodScore:    Double
    let highestMoodScore:    Double
    let lowestMoodScore:     Double
    let moodTrend:           String
    let dominantTopics:      [String]
    let topEmotions:         [String]
    let moodCategoryDistribution: [String: Double]?
    let energyDistribution:  [String: Int]
    let bestDay:             String?
    let worstDay:            String?
    let narrativeSummary:    String
    let dailyMoodScores:     [APIDailyMoodScore]?
}

/// Günlük bazda mood verisi — Insights weekly chart ve emotion distribution
struct APIDailyMoodScore: Decodable {
    let date:      String
    let moodScore: Double
    let moodLabel: String?
}

// MARK: — Calendar

struct APICalendarMonth: Decodable {
    let year:         Int
    let month:        Int
    let days:         [APICalendarDay]
    let monthSummary: APIMonthSummary?
}

struct APICalendarDay: Decodable {
    let day:              Int
    let moodLabel:        String?   // nil = no entry
    let entryId:          String?
    let moodScore:        Double?   // 0.0-1.0 scale
    let moodCategory:     String?   // "STRESS" | "NEUTRAL" | "CALM" | "MOTIVATED"
    let entryCount:       Int?
    let dominantEmotion:  String?
    let hasCoachSession:  Bool?

    var resolvedMoodCategory: MoodCategory? {
        moodCategory.map(MoodCategory.init(rawBackend:))
    }
}

struct APIMonthSummary: Decodable {
    let averageMood:  Double?
    let totalEntries: Int
    let streakDays:   Int
}

// MARK: — AI Insights

struct APIAIInsightsResponse: Decodable {
    let period:         Int
    let moodScore:      Double
    let moodTrend:      String
    let themes:         [APITheme]
    let suggestions:    [APISuggestion]
    let emotionalTrend: Double
    let hasSufficientData: Bool?
    let hasPreviousPeriodData: Bool?
}

struct APIInsightsPeriodEligibility: Decodable {
    let periods: [APIInsightsPeriod]
}

struct APIInsightsPeriod: Decodable {
    let days: Int
    let unlocked: Bool
    let requiredEntries: Int
    let currentEntries: Int
}

struct APITheme: Decodable {
    let tag:       String
    let count:     Int
    let trending:  Bool
}

struct APISuggestion: Decodable {
    let title:   String
    let body:    String
    let icon:    String?
}

// MARK: — Community

struct APICommunityPost: Decodable, Identifiable {
    let id:            String
    let userId:        String?
    let displayName:   String?
    let content:       String?
    let contentType:   String
    let audioUrl:      String?
    let audioDuration: Int?
    let imageUrl:      String?
    let emoji:         String?
    let isAnonymous:   Bool
    let likesCount:    Int
    let commentsCount: Int
    let isLikedByMe:   Bool
    let createdAt:     String

    var resolvedContentType: PostContentType { PostContentType(rawBackend: contentType) }

    func copy(
        likesCount: Int? = nil,
        commentsCount: Int? = nil,
        isLikedByMe: Bool? = nil
    ) -> APICommunityPost {
        APICommunityPost(
            id: id,
            userId: userId,
            displayName: displayName,
            content: content,
            contentType: contentType,
            audioUrl: audioUrl,
            audioDuration: audioDuration,
            imageUrl: imageUrl,
            emoji: emoji,
            isAnonymous: isAnonymous,
            likesCount: likesCount ?? self.likesCount,
            commentsCount: commentsCount ?? self.commentsCount,
            isLikedByMe: isLikedByMe ?? self.isLikedByMe,
            createdAt: createdAt
        )
    }
}

extension APICommunityPost: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIPostComment: Decodable, Identifiable {
    let id:          String
    let userId:      String
    let displayName: String?
    let content:     String
    let parentId:    String?
    let likesCount:  Int
    let isLikedByMe: Bool
    let replies:     [APIPostComment]?
    let createdAt:   String

    func copy(
        likesCount: Int? = nil,
        isLikedByMe: Bool? = nil,
        replies: [APIPostComment]? = nil
    ) -> APIPostComment {
        APIPostComment(
            id: id,
            userId: userId,
            displayName: displayName,
            content: content,
            parentId: parentId,
            likesCount: likesCount ?? self.likesCount,
            isLikedByMe: isLikedByMe ?? self.isLikedByMe,
            replies: replies ?? self.replies,
            createdAt: createdAt
        )
    }
}

extension APIPostComment: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIPagedResponse<T: Decodable>: Decodable {
    let content:       [T]
    let page:          Int
    let size:          Int
    let totalElements: Int
    let totalPages:    Int
    let last:          Bool
}

// MARK: — Achievements

struct APIAchievementsResponse: Decodable {
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries:  Int
    let totalWords:    Int
    let insightScore:  Double
    let badges:        [APIBadge]
    let level:         String
    let levelMessage:  String
}

struct APIBadge: Decodable, Identifiable {
    let id:          String
    let key:         String
    let title:       String
    let emoji:       String
    let isEarned:    Bool
    let earnedAt:    String?
}

extension APIBadge: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIAchievementDetail: Decodable {
    let key: String
    let title: String
    let description: String?
    let progress: Double
    let earnedAt: String?
}

// MARK: — Time Capsule

struct APITimeCapsule: Decodable, Identifiable {
    let id:            String
    let title:         String?
    let contentType:   String
    let audioUrl:      String?
    let audioDuration: Int?
    let contentText:   String?
    let status:        String
    let sealedAt:      String
    let unlockAt:      String
    let openedAt:      String?

    var capsuleStatus: CapsuleStatus { CapsuleStatus(rawBackend: status) }
    var capsuleContentType: CapsuleContentType { CapsuleContentType(rawBackend: contentType) }
}

// MARK: — Goals

/// /api/v1/goals endpoint'inden dönen tam hedef nesnesi
struct APIGoal: Decodable, Identifiable {
    let id:                   String
    let title:                String
    let timeframe:            String?
    let goalType:             String
    let status:               String
    let sourceJournalEntryId: String?
    let detectedAt:           String
    let completedAt:          String?
    enum CodingKeys: String, CodingKey {
        case id, title, timeframe, status, detectedAt, completedAt
        case goalType             = "goal_type"
        case sourceJournalEntryId = "source_journal_entry_id"
    }
}

struct APIGoalSuggestion: Decodable, Identifiable {
    let id: String
    let goalId: String?
    let suggestionType: String
    let sourceType: String
    let title: String?
    let timeframe: String?
    let goalType: String?
    let detectedText: String?
    let reason: String?
    let confidence: Double?
    let message: String
    let primaryActionLabel: String
    let secondaryActionLabel: String
    let createdAt: String?
    let expiresAt: String?
}

// MARK: — Coach

struct APICoachSession: Decodable, Identifiable {
    let id:             String
    let title:          String?
    let startedAt:      String
    let updatedAt:      String
    let isActive:       Bool
    let journalEntryId: String?
}

extension APICoachSession: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APICoachMessage: Decodable, Identifiable {
    let id:        String
    let role:      String   // "user" | "assistant"
    let content:   String
    let createdAt: String

    var messageRole: CoachMessageRole { CoachMessageRole(rawBackend: role) }
}

// MARK: — Error

struct APIErrorResponse: Decodable {
    let code:      String
    let message:   String
    let timestamp: String?
}

// MARK: — User Stats

struct APIUserStats: Decodable {
    let totalEntries: Int
    let currentStreak: Int
    let longestStreak: Int
    let moodScoreAvg:  Double
}

// MARK: — Profile Summary (AI-generated user profile)

struct APIProfileSummary: Decodable {
    let userProfile:       String?
    let emotionalPatterns: String?
    let valuesStrengths:   String?
    let growthTrajectory:  String?
    let weeklyDigest:      String?
    let lastUpdated:       String?
}

// MARK: — Detailed Stats

struct APIDetailedStats: Decodable {
    let weeklyConsistency:    [Int]
    let averageEntriesPerWeek: Double
    let mostActiveDay:        String?
    let mostActiveHour:       Int
    let topTopicsThisMonth:   [String]
    let topEmotionsThisMonth: [String]
    let moodTrendVsLastMonth: Double
    let totalWords:           Int
    let averageEntryLength:   Int
}

// MARK: — On This Day

struct APIOnThisDayResponse: Decodable {
    let entries: [APIOnThisDayEntry]
}

struct APIOnThisDayEntry: Decodable, Identifiable {
    let id:        String
    let date:      String
    let summary:   String?
    let moodLabel: String?
    let moodScore: Double
    let yearsAgo:  Int
}

// MARK: — Void / Empty Response

/// Backend'den boş body döndüğünde kullanılır
struct APIVoidResponse: Decodable {}
