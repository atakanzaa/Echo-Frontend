import Foundation

/// Backend tarih biçimleri:
/// - Anlık zaman: Java `OffsetDateTime.toString()` → `2026-09-15T07:30Z`, `2026-09-15T10:30:15+03:00`, `2026-09-15T07:30:15.123456Z`
///   (saniye ve fraksiyon opsiyonel, ofset zorunlu).
/// - Takvim günü: `yyyy-MM-dd`.
/// Tarihler yalnız biçimlenir; iş kuralı için yeniden hesaplanmaz.
nonisolated enum BackendDate {
    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    static func instant(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return parseOffsetDateTime(Array(string.utf8))
    }

    /// `recorded_at` gibi alanlar için ofsetli ISO-8601: `2026-09-15T10:30:00+03:00`.
    static func offsetDateTimeString(from date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let offset = timeZone.secondsFromGMT(for: date)
        let sign = offset < 0 ? "-" : "+"
        let absoluteOffset = abs(offset)
        return pad(parts.year ?? 0, 4) + "-" + pad(parts.month ?? 0, 2) + "-" + pad(parts.day ?? 0, 2)
            + "T" + pad(parts.hour ?? 0, 2) + ":" + pad(parts.minute ?? 0, 2) + ":" + pad(parts.second ?? 0, 2)
            + sign + pad(absoluteOffset / 3600, 2) + ":" + pad((absoluteOffset % 3600) / 60, 2)
    }

    private static func pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }

    private static func parseOffsetDateTime(_ bytes: [UInt8]) -> Date? {
        guard bytes.count >= 16,
              let year = number(bytes, 0, 4), bytes[4] == ascii("-"),
              let month = number(bytes, 5, 2), bytes[7] == ascii("-"),
              let day = number(bytes, 8, 2), bytes[10] == ascii("T") || bytes[10] == ascii("t"),
              let hour = number(bytes, 11, 2), bytes[13] == ascii(":"),
              let minute = number(bytes, 14, 2),
              (1...12).contains(month), (1...31).contains(day), (0...23).contains(hour), (0...59).contains(minute) else {
            return nil
        }
        var index = 16
        var second = 0
        var fraction: TimeInterval = 0
        if index < bytes.count, bytes[index] == ascii(":") {
            guard let value = number(bytes, index + 1, 2), (0...60).contains(value) else { return nil }
            second = value
            index += 3
            if index < bytes.count, bytes[index] == ascii(".") || bytes[index] == ascii(",") {
                index += 1
                var digits = 0
                var nanoseconds = 0
                while index < bytes.count, isDigit(bytes[index]) {
                    if digits < 9 {
                        nanoseconds = nanoseconds * 10 + Int(bytes[index] - ascii("0"))
                        digits += 1
                    }
                    index += 1
                }
                guard digits > 0 else { return nil }
                for _ in digits..<9 { nanoseconds *= 10 }
                fraction = TimeInterval(nanoseconds) / 1_000_000_000
            }
        }
        guard index < bytes.count else { return nil }
        var offsetSeconds = 0
        if bytes[index] == ascii("Z") || bytes[index] == ascii("z") {
            index += 1
        } else if bytes[index] == ascii("+") || bytes[index] == ascii("-") {
            let sign = bytes[index] == ascii("-") ? -1 : 1
            guard let offsetHours = number(bytes, index + 1, 2) else { return nil }
            index += 3
            var offsetMinutes = 0
            if index < bytes.count, bytes[index] == ascii(":") {
                guard let value = number(bytes, index + 1, 2) else { return nil }
                offsetMinutes = value
                index += 3
            } else if let value = number(bytes, index, 2) {
                offsetMinutes = value
                index += 2
            }
            offsetSeconds = sign * (offsetHours * 3600 + offsetMinutes * 60)
        } else {
            return nil
        }
        // ZonedDateTime biçimindeki `[Europe/Istanbul]` eki yok sayılır.
        guard index == bytes.count || bytes[index] == ascii("[") else { return nil }

        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        guard let utcDate = utcCalendar.date(from: components) else { return nil }
        return utcDate.addingTimeInterval(fraction - TimeInterval(offsetSeconds))
    }

    fileprivate static func number(_ bytes: [UInt8], _ start: Int, _ length: Int) -> Int? {
        guard start >= 0, start + length <= bytes.count else { return nil }
        var value = 0
        for index in start..<(start + length) {
            guard isDigit(bytes[index]) else { return nil }
            value = value * 10 + Int(bytes[index] - ascii("0"))
        }
        return value
    }

    fileprivate static func isDigit(_ byte: UInt8) -> Bool { byte >= ascii("0") && byte <= ascii("9") }
    fileprivate static func ascii(_ character: Unicode.Scalar) -> UInt8 { UInt8(character.value) }
}

/// Zaman diliminden bağımsız takvim günü (`yyyy-MM-dd`). Backend'in sabitlediği `entry_date` gibi alanlar için.
nonisolated struct LocalDay: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init?(_ string: String?) {
        guard let string else { return nil }
        let bytes = Array(string.utf8)
        guard bytes.count >= 10,
              let year = BackendDate.number(bytes, 0, 4), bytes[4] == BackendDate.ascii("-"),
              let month = BackendDate.number(bytes, 5, 2), bytes[7] == BackendDate.ascii("-"),
              let day = BackendDate.number(bytes, 8, 2),
              (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }
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
        let paddedMonth = month < 10 ? "0\(month)" : "\(month)"
        let paddedDay = day < 10 ? "0\(day)" : "\(day)"
        return "\(year)-\(paddedMonth)-\(paddedDay)"
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
