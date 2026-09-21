import Foundation

#if DEBUG
/// Yalnız preview verisi (implementation.md Bölüm 6, P4). Uygulama akışında kullanılmaz.
nonisolated enum EchoMockData {
    static let moodPoints: [EchoMoodPoint] = {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let scores: [Double?] = [0.42, 0.55, nil, 0.68, 0.72, 0.35, 0.80]
        return scores.enumerated().map { index, score in

            let date = calendar.date(byAdding: .day, value: index - 6, to: today) ?? today
            return EchoMoodPoint(id: "point-\(index)", date: date, score: score,
                                 caption: score.map { EchoMoodLevel(moodScore: $0).labelText }, entryCount: score == nil ? 0 : 1)
        }
    }()

    static let entry = EchoEntryCard.Model(
        id: "entry-1",
        recordedAt: Date().addingTimeInterval(-3_600),
        title: "Sabah düşünceleri",
        snippet: "Bugün kendimi şaşırtıcı derecede dingin hissettim. Sabah yürüyüşü sanırım işe yaradı.",
        moodLevel: .good,
        moodLabel: "Sakin",
        topics: ["yürüyüş", "uyku"],
        audioDurationSeconds: 134,
        waveformSamples: (0..<60).map { Float(abs(sin(Double($0) / 5)) * 0.7 + 0.15) },
        statusText: nil)

    static let processingEntry = EchoEntryCard.Model(
        id: "entry-2",
        recordedAt: Date(),
        title: nil,
        snippet: "Toplantı sonrası aklımdan geçenleri kaydettim.",
        moodLevel: nil,
        moodLabel: nil,
        topics: [],
        audioDurationSeconds: nil,
        waveformSamples: [],
        statusText: "Analiz sürüyor")

    static let earnedBadge = EchoAchievementTile.Model(
        id: "first_entry", title: "İlk Adım", emoji: "👣", isEarned: true, progress: 1, earnedAtText: "10 Eylül")

    static let lockedBadge = EchoAchievementTile.Model(
        id: "seven_day_streak", title: "İstikrar Ustası", emoji: "👑", isEarned: false, progress: 0.42, earnedAtText: nil)
}
#endif
