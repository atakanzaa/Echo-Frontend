import SwiftUI

/// Mood ölçeği (implementation.md §3.2): renk **+ şekil**. Renk tek başına anlam taşımaz.
nonisolated enum EchoMoodLevel: Int, CaseIterable, Sendable, Comparable {
    case heavy = 1
    case low
    case neutral
    case good
    case bright

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Sunucunun `mood_category` sözlüğünden ölçek seviyesi. Bilinmeyen değer nötr görünür.
    init(moodCategory: String?) {
        switch moodCategory {
        case "stress": self = .low
        case "neutral": self = .neutral
        case "calm": self = .good
        case "motivated": self = .bright
        default: self = .neutral
        }
    }

    /// 0–1 aralığındaki sunucu skoru. Yalnız gösterim içindir; eşikler karar üretmez.
    init(moodScore: Double) {
        switch moodScore {
        case ..<0.2: self = .heavy
        case ..<0.4: self = .low
        case ..<0.6: self = .neutral
        case ..<0.8: self = .good
        default: self = .bright
        }
    }

    var color: Color {
        switch self {
        case .heavy: AppTheme.color.mood.heavy
        case .low: AppTheme.color.mood.low
        case .neutral: AppTheme.color.mood.neutral
        case .good: AppTheme.color.mood.good
        case .bright: AppTheme.color.mood.bright
        }
    }

    /// Renk körlüğü uyumu için her seviyenin ayrı şekli var.
    var systemImage: String {
        switch self {
        case .heavy: "cloud.rain.fill"
        case .low: "cloud.fill"
        case .neutral: "circle.fill"
        case .good: "sun.max.fill"
        case .bright: "sparkles"
        }
    }
}

/// Mood'u renk ve şekille birlikte gösteren küçük işaret.
struct EchoMoodGlyph: View {
    let level: EchoMoodLevel
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: level.systemImage)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(level.color)
            .accessibilityHidden(true)
    }
}

#Preview("Mood ölçeği") {
    HStack(spacing: AppTheme.space.sm) {
        ForEach(EchoMoodLevel.allCases, id: \.rawValue) { level in

            EchoMoodGlyph(level: level, size: 24)
        }
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
