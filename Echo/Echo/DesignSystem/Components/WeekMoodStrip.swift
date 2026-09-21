import SwiftUI

/// Son 7 günün mood şeridi (HANDOFF §5). Her gün sunucunun `weekly_trend` noktasıdır; istemci değer üretmez.
/// Dolu gün: mood renginde "gökyüzü" sütunu, üstünde mood şekli ve kayıt sayısı kadar halka.
/// Boş geçmiş gün: kesikli çerçeve. Bugün: vurgulu sütun; boşsa davet halkaları.
struct WeekMoodStrip: View {
    nonisolated struct Day: Identifiable, Equatable, Sendable {
        let id: String
        let shortLabel: String
        let accessibilityName: String
        let moodScore: Double?
        let entryCount: Int
        let isToday: Bool

        var level: EchoMoodLevel? { moodScore.map(EchoMoodLevel.init(moodScore:)) }
    }

    let days: [Day]
    var onTap: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let plotTop: CGFloat = 18
    private let plotBottom: CGFloat = 108
    private let columnBottom: CGFloat = 124
    private let columnWidth: CGFloat = 28

    var body: some View {
        Button { onTap?() } label: {
            VStack(spacing: AppTheme.space.xxs) {
                Canvas { canvas, size in

                    draw(in: &canvas, size: size)
                }
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 150 : 130)
                labels
            }
            .background(alignment: .top) { todayColumn }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
        .accessibilityAddTraits(.isButton)
    }

    private var labels: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in

                VStack(spacing: 3) {
                    Text(day.isToday ? String(localized: "today.week.today") : day.shortLabel)
                        .echoTextStyle(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(day.isToday ? AppTheme.color.content.accent : AppTheme.color.content.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    countMarks(day.entryCount)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    @ViewBuilder private func countMarks(_ count: Int) -> some View {
        if count == 0 {

            Capsule().fill(AppTheme.color.border.default).frame(width: 8, height: 1.5).frame(height: 5)
        } else {
            HStack(spacing: 3) {
                ForEach(0..<min(count, 4), id: \.self) { _ in

                    Circle().fill(AppTheme.color.content.tertiary).frame(width: 4, height: 4)
                }
            }
            .frame(height: 5)
        }
    }

    /// Bugünün sütunu `bg.accentSoft` zeminle ayrışır.
    private var todayColumn: some View {
        GeometryReader { proxy in

            if let index = days.firstIndex(where: \.isToday) {

                let width = proxy.size.width / CGFloat(max(days.count, 1))
                RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous)
                    .fill(AppTheme.color.bg.accentSoft)
                    .frame(width: width - 6, height: proxy.size.height)
                    .offset(x: width * CGFloat(index) + 3)
            }
        }
        .allowsHitTesting(false)
    }

    private func y(for score: Double) -> CGFloat {
        plotBottom - CGFloat(min(max(score, 0), 1)) * (plotBottom - plotTop)
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize) {
        let slot = size.width / CGFloat(max(days.count, 1))
        func centerX(_ index: Int) -> CGFloat { slot * (CGFloat(index) + 0.5) }

        // Ardışık dolu günleri bağlayan yumuşak çizgi; kayıtsız günde kopar.
        var segment: [CGPoint] = []
        func flush() {
            if segment.count > 1 {

                canvas.stroke(catmullRom(segment), with: .color(AppTheme.color.content.secondary.opacity(0.45)), lineWidth: 1.5)
            }
            segment = []
        }
        for (index, day) in days.enumerated() {

            if let score = day.moodScore { segment.append(CGPoint(x: centerX(index), y: y(for: score))) } else { flush() }
        }
        flush()

        for (index, day) in days.enumerated() {

            let x = centerX(index)
            if let score = day.moodScore, let level = day.level {

                let top = y(for: score)
                let column = CGRect(x: x - columnWidth / 2, y: top, width: columnWidth, height: columnBottom - top)
                canvas.fill(Path(roundedRect: column, cornerRadius: columnWidth / 2),
                            with: .linearGradient(Gradient(colors: [level.color.opacity(0.34), level.color.opacity(0.02)]),
                                                  startPoint: CGPoint(x: x, y: top), endPoint: CGPoint(x: x, y: columnBottom)))
                for ring in 0..<min(day.entryCount, 3) {

                    let radius = 12 + CGFloat(ring) * 5
                    canvas.stroke(Path(ellipseIn: CGRect(x: x - radius, y: top - radius, width: radius * 2, height: radius * 2)),
                                  with: .color(level.color.opacity(ring == 0 ? 0.55 : 0.30)), lineWidth: 1.2)
                }
                canvas.fill(Path(ellipseIn: CGRect(x: x - 10, y: top - 10, width: 20, height: 20)),
                            with: .color(AppTheme.color.bg.surface))
                let glyph = CGRect(x: x - 7.5, y: top - 7.5, width: 15, height: 15)
                canvas.fill(EchoMoodShape(level: level).path(in: glyph), with: .color(level.color))
            } else if day.isToday {

                let center = CGPoint(x: x, y: (plotTop + plotBottom) / 2)
                for ring in 0..<3 {

                    let radius = 6 + CGFloat(ring) * 6
                    canvas.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                                  with: .color(AppTheme.color.content.accent.opacity(0.6 - Double(ring) * 0.15)),
                                  style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            } else {
                let column = CGRect(x: x - columnWidth / 2, y: plotTop, width: columnWidth, height: columnBottom - plotTop)
                canvas.stroke(Path(roundedRect: column, cornerRadius: columnWidth / 2),
                              with: .color(AppTheme.color.border.default),
                              style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }
        }
    }

    /// Noktalardan geçen Catmull-Rom eğrisi (Bezier'e çevrilmiş).
    private func catmullRom(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for index in 0..<(points.count - 1) {

            let p0 = points[max(index - 1, 0)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(index + 2, points.count - 1)]
            let control1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let control2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: control1, control2: control2)
        }
        return path
    }

    private var accessibilitySummary: String {
        let parts = days.map { day -> String in

            let name = day.isToday ? String(localized: "today.week.today") : day.accessibilityName
            guard let level = day.level else { return name + ": " + String(localized: "today.week.a11yNoEntry") }
            return name + ": " + level.labelText + ", " + String(format: String(localized: "today.week.a11yEntries"), day.entryCount)
        }
        return String(localized: "today.week.a11yTitle") + ". " + parts.joined(separator: "; ")
    }
}

/// Tema çipi: etiket, sayı ve yükseliş işareti (§5). Sayı sunucudan gelir.
struct EchoThemeChip: View {
    let tag: String
    let count: Int
    let isTrending: Bool

    var body: some View {
        HStack(spacing: AppTheme.space.xxxs) {
            Text(tag).echoTextStyle(.subhead).fontWeight(.semibold)
                .foregroundStyle(AppTheme.color.content.primary)
            Text(verbatim: "\(count)").echoTextStyle(.subhead).monospacedDigit()
                .foregroundStyle(AppTheme.color.content.secondary)
            if isTrending {

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.color.content.accent)
            }
        }
        .padding(.horizontal, AppTheme.space.xs)
        .frame(minHeight: 32)
        .background(Capsule().fill(AppTheme.color.bg.surfaceRaised))
        .accessibilityElement(children: .combine)
    }
}

/// "Son 7 gün" paneli: sayfadaki tek dolgu yüzey (§0.5). Başlık, ortalama ve trend sunucudan gelir.
struct WeeklyPanel: View {
    nonisolated struct Theme: Identifiable, Equatable, Sendable {
        let tag: String
        let count: Int
        let isTrending: Bool
        var id: String { tag }
    }

    let title: String
    let days: [WeekMoodStrip.Day]
    var average: Double?
    var trend: EchoMoodTrend?
    var trendLabel: String?
    var narrative: String?
    var themes: [Theme] = []
    var isEmpty = false
    var onDayTap: (() -> Void)?
    var onMore: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.sm) {
            header
            WeekMoodStrip(days: days, onTap: onDayTap)
            MoodLegend()
            Text("today.week.howToRead")
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
                .fixedSize(horizontal: false, vertical: true)
            if !isEmpty, let narrative {

                EchoHairline()
                reflection(narrative)
            }
            if let onMore, !isEmpty {

                EchoHairline()
                Button(action: onMore) {
                    HStack {
                        Text("today.week.more").echoTextStyle(.subhead).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.color.content.accent)
                    .frame(minHeight: AppTheme.layout.minTouchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.space.md)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous).fill(AppTheme.color.bg.surface))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).echoTextStyle(.sectionTitle).foregroundStyle(AppTheme.color.content.primary)
                if isEmpty {

                    Text("today.week.emptyBody").echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let average {

                    let level = EchoMoodLevel(moodScore: average)
                    HStack(spacing: AppTheme.space.xxxs) {
                        Text("today.week.average").echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.secondary)
                        EchoMoodGlyph(level: level, size: 11)
                        Text(level.labelKey).echoTextStyle(.subhead).fontWeight(.semibold)
                            .foregroundStyle(AppTheme.color.content.primary)
                        Text(average, format: .number.precision(.fractionLength(2)))
                            .echoTextStyle(.subhead).monospacedDigit()
                            .foregroundStyle(AppTheme.color.content.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Spacer(minLength: AppTheme.space.xs)
            if let trend, let trendLabel {

                TrendBadge(trend: trend, label: trendLabel)
            }
        }
    }

    private func reflection(_ narrative: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            HStack(spacing: AppTheme.space.xxs) {
                EchoRings(count: 2, baseRadius: 3, step: 4, color: AppTheme.color.content.accent, opacityRange: 0.4...0.9)
                    .frame(width: 16, height: 16)
                Text("today.week.reflection").echoTextStyle(.footnote).fontWeight(.semibold)
                    .foregroundStyle(AppTheme.color.content.secondary)
            }
            (Text(verbatim: "“").foregroundColor(AppTheme.color.content.accent)
             + Text(narrative).foregroundColor(AppTheme.color.content.primary)
             + Text(verbatim: "”").foregroundColor(AppTheme.color.content.accent))
                .echoTextStyle(.entry)
                .fixedSize(horizontal: false, vertical: true)
            if !themes.isEmpty {

                FlowLayout(spacing: AppTheme.space.xxs) {
                    ForEach(themes.prefix(3)) { theme in

                        EchoThemeChip(tag: theme.tag, count: theme.count, isTrending: theme.isTrending)
                    }
                }
            }
        }
    }
}
