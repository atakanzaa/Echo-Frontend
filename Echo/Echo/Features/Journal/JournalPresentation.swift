import Foundation

/// Journal ekranlarının ortak, yalnızca sunucu verisini biçimlendiren sunum yardımcıları.
nonisolated enum JournalPresentation {
    static func cardModel(for entry: JournalEntry) -> EchoEntryCard.Model {
        EchoEntryCard.Model(
            id: entry.id,
            recordedAt: entry.recordedAt,
            title: entry.analysis?.summary,
            snippet: entry.transcript,
            moodLevel: entry.analysis?.moodCategory.displayLevel,
            moodLabel: entry.analysis?.moodLabel,
            topics: entry.analysis?.topics ?? [],
            audioDurationSeconds: entry.audioDurationSeconds,
            waveformSamples: [],
            statusText: statusText(for: entry)
        )
    }

    static func statusText(for entry: JournalEntry) -> String? {
        if entry.analysis != nil, entry.status.isSucceeded { return nil }
        switch entry.status {
        case .failed:
            return String(localized: "journal.status.failed")
        case .cancelled:
            return String(localized: "journal.status.cancelled")
        case .queued, .processing, .retryScheduled, .unknown:
            return String(localized: "journal.status.processing")
        case .succeeded:
            return nil
        }
    }

    static func errorMessage(_ error: AppError) -> String {
        error.serverMessage
            ?? error.messageKey.map { String(localized: String.LocalizationValue($0)) }
            ?? String(localized: "error.unexpected")
    }

    static func monthTitle(year: Int, month: Int, locale: Locale) -> String {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = 1
        guard let date = components.date else { return "\(month)/\(year)" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    static func dayTitle(_ day: LocalDay, locale: Locale, timeZone: TimeZone) -> String {
        guard let date = day.startDate(in: timeZone) else { return day.isoString }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

nonisolated struct JournalMonthGroup: Identifiable, Hashable {
    let year: Int
    let month: Int

    var id: String { "\(year)-\(month)" }
}
