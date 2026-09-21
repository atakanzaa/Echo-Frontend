#if DEBUG
import SwiftUI
import EchoAPI

/// Bugün ekranının dört durumu (HANDOFF §11). Veri API'nin wire biçimindeki JSON'dan çözülür;
/// böylece önizleme de uygulamadaki DTO → model eşlemesinden geçer.
nonisolated enum TodayPreviewState: String, CaseIterable, Sendable {
    case newUser
    case morning
    case evening
    case offline
}

nonisolated enum TodayPreviewFixtures {
    static func decode<T: Decodable>(_ json: String) -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = formatter.date(from: text) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: text))
            }
            return date
        }
        do {
            return try decoder.decode(T.self, from: Data(json.utf8))
        } catch {
            fatalError("Önizleme verisi çözülemedi: \(error)")
        }
    }

    static func user(_ state: TodayPreviewState) -> AuthenticatedUser {
        let isNew = state == .newUser
        let recordedToday = state == .evening || state == .offline
        return AuthenticatedUser(dto: decode("""
        {"id":"u1","email":"atakan@example.com","display_name":"Atakan","timezone":"Europe/Istanbul",
         "current_streak":\(isNew ? 0 : (recordedToday ? 13 : 12)),"longest_streak":\(isNew ? 0 : 21),
         "total_entries":\(isNew ? 0 : 148),"mood_score_avg":\(isNew ? "null" : "0.64"),"language":"tr",
         "email_verified":true,"password_login_enabled":true,"role":"user","recorded_today":\(recordedToday)}
        """))
    }

    static func calendar(_ state: TodayPreviewState) -> CalendarMonth {
        let count = (state == .evening || state == .offline) ? 2 : 0
        return CalendarMonth(dto: decode("""
        {"year":2026,"month":9,"today":"2026-09-21",
         "days":[{"day":21,"mood_label":null,"entry_id":null,"mood_score":null,"mood_category":null,
                  "entry_count":\(count),"dominant_emotion":null,"has_coach_session":false}],
         "month_summary":{"average_mood":null,"total_entries":\(count),"active_days":\(count > 0 ? 1 : 0)}}
        """))
    }

    private static func entryJSON(id: String, at: String, day: String, status: String, transcript: String,
                                  analysis: String?, operation: String?) -> String {
        """
        {"id":"\(id)","recorded_at":"\(at)","entry_date":"\(day)","audio_duration_seconds":null,
         "transcript":"\(transcript)","status":"\(status)","error_code":null,
         "analysis":\(analysis ?? "null"),"created_at":"\(at)","operation_id":\(operation.map { "\"\($0)\"" } ?? "null")}
        """
    }

    static func todayEntries(_ state: TodayPreviewState) -> [JournalEntry] {
        guard state == .evening || state == .offline else { return [] }
        let morning = entryJSON(id: "e1", at: "2026-09-21T05:14:00.000Z", day: "2026-09-21", status: "succeeded",
                                transcript: "Sprint planlamasından önce işleri sıraya koydum.",
                                analysis: """
                                {"summary":"Güne erken başladın. Sprint planlamasından önce işleri sıraya koymak kafanı hafifletti.",
                                 "mood_score":0.68,"mood_label":"Odaklı","mood_category":"calm","topics":["iş","planlama"],
                                 "reflective_question":"Yarın kendine nerede bir nefes alanı açabilirsin?",
                                 "key_emotions":["odak"],"energy_level":"medium"}
                                """, operation: nil)
        let evening = entryJSON(id: "e2", at: "2026-09-21T16:42:00.000Z", day: "2026-09-21",
                                status: state == .offline ? "failed" : "processing",
                                transcript: "Akşam koşusundan yeni döndüm, bacaklarım ağır ama kafam sabahkinden çok daha hafif…",
                                analysis: nil, operation: "op2")
        return [evening, morning].map { JournalEntry(dto: decode($0)) }
    }

    static func recentEntries(_ state: TodayPreviewState) -> [JournalEntry] {
        guard state != .newUser else { return [] }
        let yesterday = entryJSON(id: "e0", at: "2026-09-20T18:05:00.000Z", day: "2026-09-20", status: "succeeded",
                                  transcript: "Uzun bir gündü.",
                                  analysis: """
                                  {"summary":"Uzun bir iş günü ve akşamında kısa bir yürüyüş.","mood_score":0.72,"mood_label":"Sakin",
                                   "mood_category":"calm","topics":["iş","yürüyüş"],
                                   "reflective_question":"Bugün seni en çok ne yordu?","key_emotions":["yorgunluk"],"energy_level":"low"}
                                  """, operation: nil)
        return todayEntries(state) + [JournalEntry(dto: decode(yesterday))]
    }

    static func weekly(_ state: TodayPreviewState) -> AIInsights {
        let isNew = state == .newUser
        let hasToday = state == .evening || state == .offline
        let days = ["2026-09-15", "2026-09-16", "2026-09-17", "2026-09-18", "2026-09-19", "2026-09-20", "2026-09-21"]
        let scores: [String] = isNew ? Array(repeating: "null", count: 7)
            : ["0.66", "0.48", "0.32", "0.50", "0.80", "0.86", hasToday ? "0.68" : "null"]
        let counts: [Int] = isNew ? Array(repeating: 0, count: 7) : [1, 2, 1, 1, 2, 1, hasToday ? 2 : 0]
        let points = zip(days, zip(scores, counts)).map { day, value in
            "{\"date\":\"\(day)\",\"mood_score\":\(value.0),\"entry_count\":\(value.1)}"
        }.joined(separator: ",")
        let themes = isNew ? "" : """
        {"tag":"iş","count":4,"trending":true},{"tag":"yürüyüş","count":3,"trending":true},{"tag":"uyku","count":2,"trending":false}
        """
        return AIInsights(dto: decode("""
        {"period":7,"period_label":"Son 7 gün","mood_score":\(isNew ? "null" : "0.64"),"mood_trend":\(isNew ? "null" : "\"improving\""),
         "themes":[\(themes)],"suggestions":[],"weekly_trend":[\(points)],"weekly_average":\(isNew ? "null" : "0.64"),
         "mood_category_stats":[],"emotional_trend":null,"has_sufficient_data":\(!isNew),
         "has_previous_period_data":\(!isNew),"entry_count":\(isNew ? 0 : 8),"recorded_days":\(isNew ? 0 : 6)}
        """))
    }

    static func summary() -> PeriodSummary {
        PeriodSummary(dto: decode("""
        {"start_date":"2026-09-15","end_date":"2026-09-21","period_days":7,"entry_count":8,"recorded_days":6,
         "coverage_percent":85.7,"average_mood_score":0.64,"highest_mood_score":0.86,"lowest_mood_score":0.32,
         "mood_trend":"improving","dominant_topics":["iş","yürüyüş"],"top_emotions":["odak"],"energy_distribution":[],
         "mood_category_distribution":[],"best_day":"2026-09-20","worst_day":"2026-09-17",
         "narrative_summary":"Bu hafta 6 gün yazdın. Hafta ortasında iş yoğunluğu ruh hâlini düşürdü, cumartesi yürüyüşünden sonra belirgin biçimde toparlandın.",
         "daily_mood_scores":[]}
        """))
    }

    static func achievements(_ state: TodayPreviewState) -> Achievements {
        let isNew = state == .newUser
        let next = isNew
            ? """
              {"key":"first_entry","title":"İlk Adım","emoji":"🌱","description":"Günlük yolculuğunun ilk adımını attın.",
               "criteria_description":"İlk kaydınla kazanırsın","is_earned":false,"earned_at":null,"progress":0,"remaining":1}
              """
            : """
              {"key":"seven_day_streak","title":"İstikrar Ustası","emoji":"👑","description":"Yedi günlük bir seri oluşturdun.",
               "criteria_description":"Üst üste 7 gün günlük tut","is_earned":false,"earned_at":null,"progress":0.42,"remaining":4}
              """
        let message = isNew ? "Henüz aktif bir serin yok. Bugün bir kayıt serini başlatır."
            : "12 gündür aralıksız devam ediyorsun. İstikrarın karşılığını veriyor."
        return Achievements(dto: decode("""
        {"current_streak":\(isNew ? 0 : 12),"longest_streak":\(isNew ? 0 : 21),"total_entries":\(isNew ? 0 : 148),
         "total_words":\(isNew ? 0 : 5120),"insight_score":\(isNew ? 0 : 42),"streak_message":"\(message)",
         "earned_count":\(isNew ? 0 : 2),"total_count":6,"badges":[\(next)],"next_badge":\(next),
         "level":"Başlangıç","level_message":"Bugün başla; küçük adımlar büyük fark yaratır."}
        """))
    }

    static func capsules(_ state: TodayPreviewState) -> CapsuleSummary? {
        switch state {
        case .newUser: return nil
        case .morning:
            return CapsuleSummary(dto: decode("""
            {"sealed_count":2,"opened_count":1,"openable_count":1,"next_capsule_id":"c1","next_unlock_at":null}
            """))
        case .evening, .offline:
            return CapsuleSummary(dto: decode("""
            {"sealed_count":1,"opened_count":2,"openable_count":0,"next_capsule_id":"c2","next_unlock_at":"2026-09-28T07:00:00.000Z"}
            """))
        }
    }

    static func goals(_ state: TodayPreviewState) -> [Goal] {
        guard state != .newUser else { return [] }
        let done = state == .evening || state == .offline
        return [
            Goal(dto: decode("""
            {"id":"g1","title":"Her sabah 10 dk yürü","timeframe":"Günlük","goal_type":"habit","creation_type":"manual",
             "status":"\(done ? "completed" : "active")","source_journal_entry_id":null,"detected_at":"2026-09-01T07:00:00.000Z",
             "completed_at":\(done ? "\"2026-09-21T06:00:00.000Z\"" : "null"),"completion_type":\(done ? "\"manual\"" : "null")}
            """)),
            Goal(dto: decode("""
            {"id":"g2","title":"Telefonu 23:00’te bırak","timeframe":"Günlük","goal_type":"habit","creation_type":"manual",
             "status":"active","source_journal_entry_id":null,"detected_at":"2026-09-05T07:00:00.000Z",
             "completed_at":null,"completion_type":null}
            """))
        ]
    }

    static func goalStats(_ state: TodayPreviewState) -> GoalStats {
        GoalStats(dto: decode("""
        {"active_count":\(state == .newUser ? 0 : 2),"completed_count":\(state == .newUser ? 0 : 14),"dismissed_count":0,
         "completed_this_week":\(state == .newUser ? 0 : 5),"week_start":"2026-09-21"}
        """))
    }

    static func suggestions(_ state: TodayPreviewState) -> [GoalSuggestion] {
        guard state != .newUser else { return [] }
        return [GoalSuggestion(dto: decode("""
        {"id":"gs1","goal_id":null,"suggestion_type":"create_goal","source_type":"journal","title":"Doğa yürüyüşü",
         "timeframe":"Hafta sonu","goal_type":null,"detected_text":null,"reason":null,"confidence":0.8,
         "message":"Yürüyüş yaptığın günler daha parlak geçiyor. Hafta sonu için bir doğa yürüyüşü hedefi ekleyelim mi?",
         "primary_action_label":"Hedef olarak ekle","secondary_action_label":"Şimdi değil",
         "created_at":"2026-09-20T18:10:00.000Z","expires_at":null}
        """))]
    }

    static func profile(_ state: TodayPreviewState) -> ProfileSummary? {
        guard state != .newUser else { return nil }
        return ProfileSummary(dto: decode("""
        {"user_profile":null,"emotional_patterns":"Zorlu günlerin ardından hareket etmek sana hep iyi geliyor; en çok da yalnız yürüyüşler.",
         "values_strengths":null,"growth_trajectory":null,"weekly_digest":null,"last_updated":null}
        """))
    }

    static func coachSession(_ state: TodayPreviewState) -> CoachSession? {
        guard state != .newUser else { return nil }
        return CoachSession(dto: decode("""
        {"id":"s1","title":"İş yükünü paylaşmak","started_at":"2026-09-19T19:00:00.000Z",
         "updated_at":"2026-09-19T19:20:00.000Z","is_active":false,"journal_entry_id":null}
        """))
    }

    static let vocabulary = ServerVocabulary(dto: decode("""
    {"mood_categories":[{"key":"stress","label":"Stresli"},{"key":"neutral","label":"Nötr"},{"key":"calm","label":"Sakin"},{"key":"motivated","label":"Motive"}],
     "energy_levels":[{"key":"low","label":"Düşük enerji"},{"key":"medium","label":"Dengeli enerji"},{"key":"high","label":"Yüksek enerji"}],
     "mood_trends":[{"key":"improving","label":"İyileşiyor"},{"key":"declining","label":"Geriliyor"},{"key":"stable","label":"Sabit"}],
     "goal_statuses":[{"key":"active","label":"Sürüyor"},{"key":"completed","label":"Tamamlandı"}]}
    """))
}

private let previewUnavailable = AppError.unexpectedResponse(status: nil)

nonisolated struct PreviewJournalService: JournalServicing {
    let state: TodayPreviewState
    func createFromTranscript(transcript: String, recordedAt: Date, durationSeconds: Int?, idempotencyKey: String) async throws -> JournalEntry { throw previewUnavailable }
    func createFromAudio(fileURL: URL, recordedAt: Date, durationSeconds: Int, idempotencyKey: String) async throws -> JournalEntry { throw previewUnavailable }
    func entry(id: String) async throws -> JournalEntry { throw previewUnavailable }
    func status(id: String) async throws -> OperationProgress { throw previewUnavailable }
    func operation(id: String) async throws -> OperationProgress { throw previewUnavailable }
    func recent(cursor: String?, size: Int) async throws -> ListPage<JournalEntry> {
        ListPage(items: TodayPreviewFixtures.recentEntries(state), nextCursor: nil, hasMore: false)
    }
    func entries(day: LocalDay, cursor: String?, size: Int) async throws -> ListPage<JournalEntry> {
        ListPage(items: TodayPreviewFixtures.todayEntries(state), nextCursor: nil, hasMore: false)
    }
    func search(query: String, cursor: String?, size: Int) async throws -> ListPage<JournalEntry> { .empty }
    func onThisDay() async throws -> [OnThisDayEntry] {
        guard state != .newUser else { return [] }
        return [OnThisDayEntry(id: "m1", day: LocalDay("2025-09-21"), summary: "Sahilde uzun bir yürüyüş, kafam ilk kez bu kadar boştu.",
                               moodLabel: "Sakin", moodScore: 0.72, yearsAgo: 1)]
    }
    func delete(id: String) async throws {}
}

nonisolated struct PreviewInsightsService: InsightsServicing {
    let state: TodayPreviewState
    func calendar(year: Int, month: Int) async throws -> CalendarMonth { TodayPreviewFixtures.calendar(state) }
    func summary(periodDays: Int, endDay: LocalDay?) async throws -> PeriodSummary { TodayPreviewFixtures.summary() }
    func insights(periodDays: Int) async throws -> AIInsights { TodayPreviewFixtures.weekly(state) }
    func eligibility() async throws -> InsightEligibility { throw previewUnavailable }
    func detailedStats() async throws -> DetailedStats { throw previewUnavailable }
    func profileSummary() async throws -> ProfileSummary? { TodayPreviewFixtures.profile(state) }
    func achievements() async throws -> Achievements { TodayPreviewFixtures.achievements(state) }
    func achievementDetail(badgeKey: String) async throws -> AchievementDetail { throw previewUnavailable }
}

nonisolated struct PreviewNotificationService: NotificationServicing {
    let state: TodayPreviewState
    func list(cursor: String?, size: Int) async throws -> ListPage<NotificationItem> { .empty }
    func unreadCount() async throws -> Int { state == .newUser ? 0 : 3 }
    func markRead(id: String) async throws -> Int { 0 }
    func markAllRead() async throws -> Int { 0 }
    func preferences() async throws -> NotificationPreferences { throw previewUnavailable }
    func updatePreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences { throw previewUnavailable }
    func registerPushToken(_ token: String, environment: String) async throws {}
    func unregisterPushToken(_ token: String) async throws {}
}

nonisolated struct PreviewGoalService: GoalServicing {
    let state: TodayPreviewState
    func activeGoals(cursor: String?, size: Int) async throws -> ListPage<Goal> { .empty }
    func allGoals(cursor: String?, size: Int) async throws -> ListPage<Goal> { .empty }
    func stats() async throws -> GoalStats { TodayPreviewFixtures.goalStats(state) }
    func todayGoals() async throws -> [Goal] { TodayPreviewFixtures.goals(state) }
    func create(title: String, timeframe: String?, idempotencyKey: String) async throws -> Goal { throw previewUnavailable }
    func complete(id: String) async throws -> Goal { throw previewUnavailable }
    func markNotCompleted(id: String) async throws -> Goal { throw previewUnavailable }
    func dismiss(id: String) async throws -> Goal { throw previewUnavailable }
    func delete(id: String) async throws {}
    func suggestions(sourceType: String?, suggestionType: String?, journalEntryID: String?, coachSessionID: String?) async throws -> [GoalSuggestion] {
        TodayPreviewFixtures.suggestions(state)
    }
    func acceptSuggestion(id: String) async throws -> Goal { throw previewUnavailable }
    func rejectSuggestion(id: String) async throws {}
}

nonisolated struct PreviewCapsuleService: CapsuleServicing {
    let state: TodayPreviewState
    func list(cursor: String?, size: Int) async throws -> ListPage<TimeCapsule> { .empty }
    func summary() async throws -> CapsuleSummary {
        guard let summary = TodayPreviewFixtures.capsules(state) else { throw previewUnavailable }
        return summary
    }
    func create(title: String?, text: String, unlockAt: Date, idempotencyKey: String) async throws -> TimeCapsule { throw previewUnavailable }
    func capsule(id: String) async throws -> TimeCapsule { throw previewUnavailable }
    func open(id: String) async throws -> TimeCapsule { throw previewUnavailable }
    func delete(id: String) async throws {}
}

nonisolated struct PreviewCoachService: CoachServicing {
    let state: TodayPreviewState
    func sessions(cursor: String?, size: Int) async throws -> ListPage<CoachSession> {
        ListPage(items: TodayPreviewFixtures.coachSession(state).map { [$0] } ?? [], nextCursor: nil, hasMore: false)
    }
    func createSession(journalEntryID: String?, idempotencyKey: String) async throws -> CoachSession { throw previewUnavailable }
    func messages(sessionID: String, cursor: String?, size: Int) async throws -> ListPage<CoachMessage> { .empty }
    func sendMessage(sessionID: String, content: String, idempotencyKey: String) async throws -> OperationProgress { throw previewUnavailable }
    func operation(id: String) async throws -> OperationProgress { throw previewUnavailable }
    func endSession(id: String) async throws {}
    func deleteSession(id: String) async throws {}
}

extension AppEnvironment {
    /// Ağsız önizleme ortamı: sahte servisler, oturum açık kullanıcı ve sunucu sözlüğü.
    static func preview(_ state: TodayPreviewState) -> AppEnvironment {
        let language = AppLanguageStore()
        let serverURL = URL(string: "https://preview.echo.invalid")!
        let stack = try! EchoAPIStack.make(serverURL: serverURL, keychainService: "echo.preview", language: language.headerProvider)
        var services = AppServices.live(stack)
        services.journal = PreviewJournalService(state: state)
        services.insights = PreviewInsightsService(state: state)
        services.notifications = PreviewNotificationService(state: state)
        services.goals = PreviewGoalService(state: state)
        services.capsules = PreviewCapsuleService(state: state)
        services.coach = PreviewCoachService(state: state)
        let environment = AppEnvironment(configuration: AppConfiguration(apiBaseURL: serverURL, subscriptionProductIDs: [],
                                                                         keychainService: "echo.preview"),
                                         stack: stack, language: language, services: services)
        environment.session.apply(TodayPreviewFixtures.user(state))
        environment.remoteConfig.applyPreview(vocabulary: TodayPreviewFixtures.vocabulary)
        if state == .offline { environment.network.overrideForPreview(isOnline: false) }
        return environment
    }
}

/// Önizleme ve `-EchoTodayPreview <durum>` başlatma argümanı için kabuk.
struct TodayPreviewHost: View {
    let state: TodayPreviewState
    @State private var environment: AppEnvironment
    @State private var router = AppRouter()

    init(state: TodayPreviewState) {
        self.state = state
        _environment = State(initialValue: .preview(state))
    }

    var body: some View {
        NavigationStack {
            if let user = environment.session.state.user {

                TodayView(user: user, environment: environment).echoTabBarInset()
            }
        }
        .environment(environment)
        .environment(router)
        .environment(environment.theme)
    }
}

#Preview("1 · Yeni kullanıcı — koyu") { TodayPreviewHost(state: .newUser).preferredColorScheme(.dark) }
#Preview("1 · Yeni kullanıcı — açık") { TodayPreviewHost(state: .newUser).preferredColorScheme(.light) }
#Preview("2 · Sabah — koyu") { TodayPreviewHost(state: .morning).preferredColorScheme(.dark) }
#Preview("2 · Sabah — açık") { TodayPreviewHost(state: .morning).preferredColorScheme(.light) }
#Preview("2 · Sabah — büyük yazı") {
    TodayPreviewHost(state: .morning).preferredColorScheme(.dark).dynamicTypeSize(.xxxLarge)
}
#Preview("3 · Akşam — koyu") { TodayPreviewHost(state: .evening).preferredColorScheme(.dark) }
#Preview("3 · Akşam — açık") { TodayPreviewHost(state: .evening).preferredColorScheme(.light) }
#Preview("4 · Çevrimdışı — koyu") { TodayPreviewHost(state: .offline).preferredColorScheme(.dark) }
#Preview("4 · Çevrimdışı — açık") { TodayPreviewHost(state: .offline).preferredColorScheme(.light) }
#endif
