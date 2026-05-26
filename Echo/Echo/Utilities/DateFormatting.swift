import Foundation

enum DateFormatting {
    private static func formatter(configure: (DateFormatter) -> Void) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        configure(formatter)
        return formatter
    }

    private static let iso8601Parsers: [ISO8601DateFormatter] = {
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return [fractional, standard]
    }()

    private static let iso8601Writer: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let mediumDateFormatter = formatter { $0.dateStyle = .medium }
    private static let shortDateFormatter = formatter { $0.dateStyle = .short }
    private static let shortTimeFormatter = formatter { $0.timeStyle = .short }
    private static let monthYearFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("MMMM yyyy") }
    private static let monthYearShortFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("MMM yyyy") }
    private static let weekdayMonthDayFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("EEEE MMM d") }
    private static let fullJournalDateFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("d MMMM yyyy EEEE") }
    private static let calendarDetailFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("EEEE d MMM") }
    private static let apiDateFormatter = formatter {
        $0.locale = Locale(identifier: "en_US_POSIX")
        $0.dateFormat = "yyyy-MM-dd"
    }
    private static let weekdayAbbreviationFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("EEE") }
    private static let weekdayTimeFormatter = formatter { $0.setLocalizedDateFormatFromTemplate("EEEE HHmm") }
    private static let mediumDateTimeFormatter = formatter { $0.dateStyle = .medium; $0.timeStyle = .short }
    private static let compactDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.dateFormat = "MMM d, h:mm a"
        return f
    }()

    static func parseISO8601(_ string: String) -> Date? {
        for formatter in iso8601Parsers {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    static func iso8601String(from date: Date) -> String {
        iso8601Writer.string(from: date)
    }

    static func mediumDate(from date: Date) -> String {
        mediumDateFormatter.string(from: date)
    }

    static func shortDate(from date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    static func shortTime(from date: Date) -> String {
        shortTimeFormatter.string(from: date)
    }

    static func monthYear(from date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    static func shortMonthYear(from date: Date) -> String {
        monthYearShortFormatter.string(from: date)
    }

    static func weekdayMonthDayUppercased(from date: Date) -> String {
        weekdayMonthDayFormatter.string(from: date).uppercased(with: .autoupdatingCurrent)
    }

    static func fullJournalDate(from date: Date) -> String {
        fullJournalDateFormatter.string(from: date)
    }

    static func calendarDetailDate(from date: Date) -> String {
        calendarDetailFormatter.string(from: date)
    }

    static func apiDateString(from date: Date) -> String {
        apiDateFormatter.string(from: date)
    }

    static func weekdayTime(from date: Date) -> String {
        weekdayTimeFormatter.string(from: date)
    }

    static func mediumDateTime(from date: Date) -> String {
        mediumDateTimeFormatter.string(from: date)
    }

    static func compactDateTime(from date: Date) -> String {
        compactDateTimeFormatter.string(from: date).uppercased(with: .autoupdatingCurrent)
    }

    static func weekdayAbbreviation(from dateString: String) -> String? {
        guard let date = apiDateFormatter.date(from: dateString) else { return nil }
        return weekdayAbbreviationFormatter.string(from: date)
    }
}
