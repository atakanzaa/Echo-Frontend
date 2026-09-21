import Charts
import SwiftUI

/// Grafikte bir gün. `score` null ise o gün kayıt yok demektir; sıfır gösterilmez (rules.md §12).
nonisolated struct EchoMoodPoint: Identifiable, Sendable, Equatable {
    let id: String
    let date: Date
    let score: Double?
    /// Sunucunun o gün için yazdığı etiket.
    let caption: String?
    let entryCount: Int

    init(id: String = UUID().uuidString, date: Date, score: Double?, caption: String? = nil, entryCount: Int = 0) {
        self.id = id
        self.date = date
        self.score = score
        self.caption = caption
        self.entryCount = entryCount
    }

    var level: EchoMoodLevel? { score.map(EchoMoodLevel.init(moodScore:)) }
}

/// Günlük mood grafiği (implementation.md §4.19). Her takvim günü bir nokta; kayıtsız günde nokta yok ve çizgi kopar.
/// Y ekseni sayı değil mood şekli gösterir. Tam boyutta seçili (varsayılan: son kayıtlı) gün grafiğin üstünde açıklanır.
struct EchoMoodChart: View {
    let points: [EchoMoodPoint]
    var isCompact: Bool = false
    @State private var selectedID: String?

    private var recorded: [EchoMoodPoint] { points.filter { $0.score != nil } }

    private var highlighted: EchoMoodPoint? {
        points.first { $0.id == selectedID && $0.score != nil } ?? recorded.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.sm) {
            if !isCompact, let highlighted {

                dayDetail(highlighted)
            }
            chart
                .frame(height: isCompact ? 88 : 200)
            if !isCompact {

                MoodLegend()
                Text("insights.moodMap.howToRead")
                    .echoTextStyle(.caption)
                    .foregroundStyle(AppTheme.color.content.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Kayıtsız gün serisi böler; böylece çizgi boş günün üstünden geçmez.
    private var segments: [(segment: Int, point: EchoMoodPoint)] {
        var segment = 0
        var result: [(segment: Int, point: EchoMoodPoint)] = []
        for point in points {

            if point.score == nil { segment += 1 } else { result.append((segment, point)) }
        }
        return result
    }

    /// Uçtaki noktalar kesilmesin diye alan yarım gün genişletilir.
    private var xDomain: ClosedRange<Date> {
        let dates = points.map(\.date)
        guard let first = dates.min(), let last = dates.max() else { return Date()...Date() }
        return first.addingTimeInterval(-43_200)...last.addingTimeInterval(43_200)
    }

    private var chart: some View {
        Chart {
            if !isCompact, let highlighted {

                RuleMark(x: .value("", highlighted.date))
                    .foregroundStyle(AppTheme.color.border.subtle)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            ForEach(segments, id: \.point.id) { item in

                let score = item.point.score ?? 0
                LineMark(x: .value("", item.point.date), y: .value("", score), series: .value("", item.segment))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(AppTheme.color.content.accent.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("", item.point.date), y: .value("", score))
                    .foregroundStyle(EchoMoodLevel(moodScore: score).color)
                    .symbolSize(item.point.id == highlighted?.id && !isCompact ? 150 : 70)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            if isCompact {

                AxisMarks(values: .automatic(desiredCount: 0)) { _ in }
            } else {
                AxisMarks(position: .leading, values: [0.1, 0.3, 0.5, 0.7, 0.9]) { value in

                    AxisGridLine().foregroundStyle(AppTheme.color.border.subtle)
                    AxisValueLabel {
                        if let score = value.as(Double.self) {

                            EchoMoodGlyph(level: EchoMoodLevel(moodScore: score), size: 12)
                        }
                    }
                }
            }
        }
        .chartXAxis {
            if isCompact {

                AxisMarks(values: .automatic(desiredCount: 0)) { _ in }
            } else if points.count <= 7 {

                AxisMarks(values: points.map(\.date)) { _ in

                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), anchor: .top)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            } else {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in

                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), anchor: .top)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
        }
        .chartOverlay { proxy in

            GeometryReader { geometry in

                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in

                        guard !isCompact, let plotFrame = proxy.plotFrame else { return }
                        let x = value.location.x - geometry[plotFrame].origin.x
                        guard let date: Date = proxy.value(atX: x) else { return }
                        selectedID = recorded
                            .min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?.id
                    })
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("insights.moodMap"))
        .accessibilityValue(Text(accessibilitySummary))
    }

    private func dayDetail(_ point: EchoMoodPoint) -> some View {
        HStack(spacing: AppTheme.space.xs) {
            if let level = point.level {

                EchoMoodGlyph(level: level, size: 18)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(point.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .echoTextStyle(.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.color.content.primary)
                Text(detailLine(point))
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func detailLine(_ point: EchoMoodPoint) -> String {
        let count = String(format: String(localized: "mood.entryCount"), point.entryCount)
        guard let caption = point.caption else { return count }
        return caption + " · " + count
    }

    private var accessibilitySummary: String {
        recorded.map { point in

            point.date.formatted(.dateTime.weekday(.wide).day().month(.wide)) + ": " + detailLine(point)
        }
        .joined(separator: "; ")
    }
}

#if DEBUG
/// Yalnız DEBUG: tek kayıtlı ve dolu bir hafta; `-EchoMoodChartPreview` ile de açılır.
struct MoodChartGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.space.lg) {
                EchoCard(style: .flat) { EchoMoodChart(points: Self.week([nil, nil, nil, nil, nil, nil, (0.70, 1)])) }
                EchoCard(style: .flat) {
                    EchoMoodChart(points: Self.week([(0.62, 1), (0.48, 2), (0.31, 1), nil, (0.84, 2), (0.88, 1), (0.70, 2)]))
                }
                EchoMoodChart(points: EchoMockData.moodPoints, isCompact: true)
            }
            .padding()
        }
        .background(AppTheme.color.bg.canvas)
    }

    private static func week(_ days: [(Double, Int)?]) -> [EchoMoodPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return days.enumerated().map { index, day in

            let date = calendar.date(byAdding: .day, value: index - days.count + 1, to: today) ?? today
            return EchoMoodPoint(id: "day-\(index)", date: date, score: day?.0,
                                 caption: day.map { EchoMoodLevel(moodScore: $0.0).labelText }, entryCount: day?.1 ?? 0)
        }
    }
}

#Preview("Mood grafiği") { MoodChartGallery() }
#endif
