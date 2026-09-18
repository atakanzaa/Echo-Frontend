import SwiftUI

/// Akıştaki günlük kartı (implementation.md §4.23). Tüm alanlar sunucudan gelir.
struct EchoEntryCard: View {
    nonisolated struct Model: Identifiable, Sendable, Equatable {
        let id: String
        let recordedAt: Date
        let title: String?
        let snippet: String?
        let moodLevel: EchoMoodLevel?
        let moodLabel: String?
        let topics: [String]
        let audioDurationSeconds: Int?
        let waveformSamples: [Float]
        /// Analiz sürüyorsa kart işlem durumunu gösterir; kullanıcı beklemede olduğunu bilir.
        let statusText: String?
    }

    let model: Model
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        EchoCard {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                header
                if let title = model.title {

                    Text(title)
                        .echoTextStyle(.headline)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .lineLimit(1)
                }
                if let snippet = model.snippet {

                    Text(snippet)
                        .echoTextStyle(.entry)
                        .foregroundStyle(AppTheme.color.content.secondary)
                        .lineLimit(3)
                }
                footer
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .contextMenu {
            if let onDelete {

                Button("common.delete", systemImage: "trash", role: .destructive, action: onDelete)
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppTheme.space.xxs) {
            if let level = model.moodLevel {

                EchoMoodGlyph(level: level, size: 14)
            }
            Text(model.recordedAt, format: .dateTime.day().month(.wide).hour().minute())
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
            if let moodLabel = model.moodLabel {

                Text(verbatim: "·").echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                Text(moodLabel).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var footer: some View {
        if let statusText = model.statusText {

            HStack(spacing: AppTheme.space.xxxs) {
                EchoRippleView(ringCount: 2, intensity: 0.4)
                    .frame(width: 16, height: 16)
                Text(statusText).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.secondary)
            }
        } else if !model.topics.isEmpty || model.audioDurationSeconds != nil {

            HStack(spacing: AppTheme.space.xxs) {
                if let seconds = model.audioDurationSeconds {

                    EchoWaveform(mode: .summary(samples: model.waveformSamples), height: 20)
                        .frame(width: 96)
                    Text(EchoDuration.text(seconds: seconds))
                        .echoTextStyle(.caption)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                        .monospacedDigit()
                }
                ForEach(model.topics.prefix(2), id: \.self) { topic in

                    EchoChip(topic)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

/// Saniyeyi `d:ss` biçiminde gösterir; süre sunucudan gelen değerdir.
nonisolated enum EchoDuration {
    static func text(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}

#Preview("Günlük kartı") {
    VStack(spacing: AppTheme.space.sm) {
        EchoEntryCard(model: EchoMockData.entry)
        EchoEntryCard(model: EchoMockData.processingEntry)
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
