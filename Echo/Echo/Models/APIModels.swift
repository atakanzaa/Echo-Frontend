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
}

struct APIAnalysisResult: Decodable {
    let summary:            String?
    let moodScore:          Double?
    let moodLabel:          String?
    let topics:             [String]?
    let reflectiveQuestion: String?
    let keyEmotions:        [String]?
    let energyLevel:        String?
    // Genişletilmiş analiz alanları — optional (geriye uyumlu)
    let goals:              [APIGoalPreview]?
    let insights:           [String]?
    let memoryWorthy:       Bool?
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
    let year:  Int
    let month: Int
    let days:  [APICalendarDay]
}

struct APICalendarDay: Decodable {
    let day:       Int
    let moodLabel: String?   // nil = giriş yok
    let entryId:   String?
    let moodScore: Double?   // 0.0-1.0 skalası
}

// MARK: — AI Insights

struct APIAIInsightsResponse: Decodable {
    let period:         Int
    let moodScore:      Double
    let moodTrend:      String
    let themes:         [APITheme]
    let suggestions:    [APISuggestion]
    let emotionalTrend: Double
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
}

// MARK: — Goals

/// /api/v1/goals endpoint'inden dönen tam hedef nesnesi
struct APIGoal: Decodable, Identifiable {
    let id:                   String
    let title:                String
    let timeframe:            String?
    let goalType:             String
    let status:               String   // PENDING | COMPLETED | DISMISSED
    let sourceJournalEntryId: String?
    let detectedAt:           String
    let completedAt:          String?
    enum CodingKeys: String, CodingKey {
        case id, title, timeframe, status, detectedAt, completedAt
        case goalType             = "goal_type"
        case sourceJournalEntryId = "source_journal_entry_id"
    }
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

// MARK: — Void / Empty Response

/// Backend'den boş body döndüğünde kullanılır
struct APIVoidResponse: Decodable {}
