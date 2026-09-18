import SwiftUI

/// Mood ölçeği (implementation.md §3.2): renk **+ şekil**. Renk tek başına anlam taşımaz.
nonisolated enum EchoMoodLevel: Int, CaseIterable, Sendable, Comparable, Identifiable {
    case heavy = 1
    case low
    case neutral
    case good
    case bright

    var id: Int { rawValue }

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
}

/// Renk körlüğü uyumu için her seviyenin ayrı şekli vardır (§4.18).
nonisolated struct EchoMoodShape: Shape {
    let level: EchoMoodLevel

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch level {
        case .heavy:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        case .low:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            path.closeSubpath()
        case .neutral:
            path.addEllipse(in: rect)
        case .good:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.closeSubpath()
        case .bright:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// Mood'u renk ve şekille birlikte gösteren küçük işaret.
struct EchoMoodGlyph: View {
    let level: EchoMoodLevel
    var size: CGFloat = 16
    var isFilled: Bool = true

    var body: some View {
        Group {
            if isFilled {

                EchoMoodShape(level: level).fill(level.color)
            } else {
                EchoMoodShape(level: level).stroke(level.color, lineWidth: 1.5)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Mood ölçeği") {
    HStack(spacing: AppTheme.space.sm) {
        ForEach(EchoMoodLevel.allCases) { level in

            VStack(spacing: AppTheme.space.xxs) {
                EchoMoodGlyph(level: level, size: 28)
                EchoMoodGlyph(level: level, size: 28, isFilled: false)
            }
        }
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
