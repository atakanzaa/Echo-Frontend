import Foundation

/// Zaman diliminden bağımsız takvim günü (`yyyy-MM-dd`). Sunucunun sabitlediği `entry_date`, `today`,
/// `week_start` gibi alanlar buraya çözülür; `Date`'e çevrilip saat dilimi kaydırılmaz (rules.md §11).
nonisolated struct LocalDay: Hashable, Comparable, Sendable, Identifiable {
    let year: Int
    let month: Int
    let day: Int

    var id: String { isoString }

    init?(_ string: String?) {
        guard let string else { return nil }
        let parts = string.split(separator: "-")
        guard parts.count >= 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2].prefix(2)),
              (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Verilen zaman dilimindeki gün (ör. kullanıcının backend timezone'unda "bugün").
    init(date: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year ?? 0
        month = parts.month ?? 1
        day = parts.day ?? 1
    }

    var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Biçimlendirme için günün başlangıç anı.
    func startDate(in timeZone: TimeZone) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
