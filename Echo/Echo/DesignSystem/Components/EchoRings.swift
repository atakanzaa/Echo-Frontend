import SwiftUI

/// Statik yankı halkaları (HANDOFF §5). Hareket gerektiğinde `EchoRippleView` kullanılır.
/// İçten dışa opaklık azalır; halkalar kendi çerçevesinden taşabilsin diye çağıran taraf alanı belirler.
struct EchoRings: View {
    var count: Int = 3
    var baseRadius: CGFloat = 12
    var step: CGFloat = 8
    var color: Color = AppTheme.color.accent.primary
    var opacityRange: ClosedRange<Double> = 0.06...0.55
    var lineWidth: CGFloat = 1.25
    var dashed: Bool = false

    var body: some View {
        Canvas { canvas, size in

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rings = min(max(count, 1), 6)
            for index in 0..<rings {

                let radius = baseRadius + CGFloat(index) * step
                let fraction = rings > 1 ? Double(index) / Double(rings - 1) : 0
                let opacity = opacityRange.upperBound - (opacityRange.upperBound - opacityRange.lowerBound) * fraction
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                canvas.stroke(Path(ellipseIn: rect),
                              with: .color(color.opacity(opacity)),
                              style: StrokeStyle(lineWidth: lineWidth, dash: dashed ? [3, 4] : []))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Mood ölçeğinin gösterim adları. Sunucunun 4 kategorisi ayrı sözlüktür; bu 5 seviye ekranın ölçeğidir.
extension EchoMoodLevel {
    var labelKey: LocalizedStringKey {
        switch self {
        case .heavy: "mood.level.heavy"
        case .low: "mood.level.low"
        case .neutral: "mood.level.neutral"
        case .good: "mood.level.good"
        case .bright: "mood.level.bright"
        }
    }

    var labelText: String {
        switch self {
        case .heavy: String(localized: "mood.level.heavy")
        case .low: String(localized: "mood.level.low")
        case .neutral: String(localized: "mood.level.neutral")
        case .good: String(localized: "mood.level.good")
        case .bright: String(localized: "mood.level.bright")
        }
    }
}

/// Beş seviyenin şekil + ad açıklaması; mood hiçbir yerde yalnız renkle anlatılmaz.
struct MoodLegend: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                ForEach(EchoMoodLevel.allCases) { level in

                    item(level)
                    if level != .bright { Spacer(minLength: AppTheme.space.xxs) }
                }
            }
            FlowLayout(spacing: AppTheme.space.xs) {
                ForEach(EchoMoodLevel.allCases) { level in

                    item(level)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func item(_ level: EchoMoodLevel) -> some View {
        HStack(spacing: AppTheme.space.xxxs) {
            EchoMoodGlyph(level: level, size: 12)
            Text(level.labelKey)
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.secondary)
        }
    }
}

/// Mood trendi rozeti. Metin sunucunun sözlüğünden gelir (`/app/vocabulary`); uygulama çeviri tutmaz.
struct TrendBadge: View {
    let trend: EchoMoodTrend
    let label: String

    var body: some View {
        HStack(spacing: AppTheme.space.xxxs) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .echoTextStyle(.subhead)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, AppTheme.space.xs)
        .frame(minHeight: 30)
        .background(Capsule().fill(background))
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch trend {
        case .improving: "chart.line.uptrend.xyaxis"
        case .declining: "chart.line.downtrend.xyaxis"
        case .stable, .unknown: "equal"
        }
    }

    private var tint: Color {
        switch trend {
        case .improving: AppTheme.color.accent.secondary
        case .declining: AppTheme.color.feedback.danger
        case .stable, .unknown: AppTheme.color.content.secondary
        }
    }

    private var background: Color {
        switch trend {
        case .improving: AppTheme.color.bg.aquaSoft
        case .declining: AppTheme.color.feedback.danger.opacity(0.12)
        case .stable, .unknown: AppTheme.color.bg.surfaceRaised
        }
    }
}

#Preview("Halkalar, lejant, trend — koyu") {
    tokenPreview.preferredColorScheme(.dark)
}

#Preview("Halkalar, lejant, trend — açık") {
    tokenPreview.preferredColorScheme(.light)
}

@MainActor private var tokenPreview: some View {
    VStack(alignment: .leading, spacing: AppTheme.space.lg) {
        HStack(spacing: AppTheme.space.lg) {
            EchoRings(count: 6, baseRadius: 14, step: 12).frame(width: 160, height: 160)
            EchoRings(count: 3, baseRadius: 10, step: 8, dashed: true).frame(width: 64, height: 64)
        }
        // .low kase (düz kenar üstte), .good kubbe olmalı.
        HStack(spacing: AppTheme.space.md) {
            ForEach(EchoMoodLevel.allCases) { EchoMoodGlyph(level: $0, size: 28) }
        }
        MoodLegend()
        HStack {
            TrendBadge(trend: .improving, label: "İyileşiyor")
            TrendBadge(trend: .stable, label: "Sabit")
            TrendBadge(trend: .declining, label: "Geriliyor")
        }
        Text(verbatim: "Son 7 gün").echoTextStyle(.sectionTitle)
        Text(verbatim: "Bugün seni en çok ne yordu?").echoTextStyle(.question)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppTheme.color.bg.canvas)
}
