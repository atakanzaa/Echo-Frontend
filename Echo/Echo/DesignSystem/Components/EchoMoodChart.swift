import Charts
import SwiftUI

/// Grafikte bir gün. `score` null ise o gün kayıt yok demektir; sıfır gösterilmez (rules.md §12).
nonisolated struct EchoMoodPoint: Identifiable, Sendable, Equatable {
    let id: String
    let date: Date
    let score: Double?
    let caption: String?

    init(id: String = UUID().uuidString, date: Date, score: Double?, caption: String? = nil) {
        self.id = id
        self.date = date
        self.score = score
        self.caption = caption
    }

    var level: EchoMoodLevel? { score.map(EchoMoodLevel.init(moodScore:)) }
}

/// Dot-plot + trend çizgisi (implementation.md §4.19). Y ekseni sayı değil mood şekli gösterir.
struct EchoMoodChart: View {
    let points: [EchoMoodPoint]
    var isCompact: Bool = false
    @State private var selectedID: String?

    private var selected: EchoMoodPoint? {
        points.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            if let selected, !isCompact {

                tooltip(for: selected)
            }
            chart
                .frame(height: isCompact ? 88 : 200)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in

                if let score = point.score {

                    LineMark(x: .value("", point.date), y: .value("", score))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.color.content.accent.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(x: .value("", point.date), y: .value("", score))
                        .foregroundStyle(EchoMoodLevel(moodScore: score).color)
                        .symbolSize(selectedID == point.id ? 140 : 70)
                } else {
                    // Kayıtsız gün: içi boş daire; çizgi bu günde kesilir.
                    PointMark(x: .value("", point.date), y: .value("", 0.5))
                        .foregroundStyle(AppTheme.color.border.subtle)
                        .symbolSize(36)
                        .symbol(.circle)
                        .opacity(0.6)
                }
            }
        }
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
            } else {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in

                    AxisValueLabel(format: .dateTime.day().month(.narrow))
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
                        selectedID = points
                            .filter { $0.score != nil }
                            .min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?.id
                    })
            }
        }
    }

    private func tooltip(for point: EchoMoodPoint) -> some View {
        EchoCard(style: .flat, padding: AppTheme.layout.cardPaddingCompact) {
            HStack(spacing: AppTheme.space.xxs) {
                if let level = point.level {

                    EchoMoodGlyph(level: level, size: 16)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.date, format: .dateTime.day().month(.wide))
                        .echoTextStyle(.subhead)
                        .foregroundStyle(AppTheme.color.content.primary)
                    if let caption = point.caption {

                        Text(caption)
                            .echoTextStyle(.footnote)
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview("Mood grafiği") {
    VStack(spacing: AppTheme.space.lg) {
        EchoMoodChart(points: EchoMockData.moodPoints)
        EchoMoodChart(points: EchoMockData.moodPoints, isCompact: true)
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
