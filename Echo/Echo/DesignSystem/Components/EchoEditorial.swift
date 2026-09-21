import SwiftUI

/// Bugün ekranının editoryal parçaları (docs/design/today/HANDOFF.md §5). Kart yığını yok:
/// bölümler tipografi, boşluk ve ince çizgiyle ayrılır; tek dolgu yüzey "Son 7 gün" panelidir.

/// Bölüm başlığı: `.sectionTitle`, opsiyonel alt satır ve sağda metin bağlantısı.
struct EchoSectionTitle: View {
    let title: String
    var subtitle: String?
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .echoTextStyle(.sectionTitle)
                    .foregroundStyle(AppTheme.color.content.primary)
                if let subtitle {

                    Text(subtitle)
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
            }
            Spacer(minLength: AppTheme.space.xs)
            if let actionTitle, let action {

                Button(action: action) {
                    Text(actionTitle)
                        .echoTextStyle(.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.color.content.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Satırlar arası ince çizgi.
struct EchoHairline: View {
    var leadingInset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(AppTheme.color.border.subtle)
            .frame(height: 0.5)
            .padding(.leading, leadingInset)
            .accessibilityHidden(true)
    }
}

/// Günün sorusu (§5): etiket → serif soru → metin düzeyinde eylem. Dolu düğme yok; kayıt düğmesi sekme çubuğunda.
/// Arkada statik yankı halkaları, merkezinde soruyu doğuran kaydın mood şekli.
struct EchoQuestionHero: View {
    let label: String?
    let question: String
    var message: String?
    var moodLevel: EchoMoodLevel?
    let actionTitle: LocalizedStringKey
    let writeTitle: LocalizedStringKey
    let onRecord: () -> Void
    let onWrite: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: onRecord) {
                VStack(alignment: .leading, spacing: AppTheme.space.sm) {
                    if let label {

                        Text(label)
                            .echoTextStyle(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.color.content.secondary)
                    }
                    Text(question)
                        .echoTextStyle(.question)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    if let message {

                        Text(message)
                            .echoTextStyle(.callout)
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Label(actionTitle, systemImage: "mic")
                        .echoTextStyle(.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.color.content.accent)
                        .padding(.top, AppTheme.space.xxxs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("today.question.a11yLabel \(question)"))
            .accessibilityHint(Text("today.question.a11yHint"))

            Button(action: onWrite) {
                Label(writeTitle, systemImage: "square.and.pencil")
                    .echoTextStyle(.subhead)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .frame(minHeight: AppTheme.layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(alignment: .trailing) {
            ZStack {
                EchoRings(count: 6, baseRadius: 30, step: 30,
                          color: (moodLevel?.color ?? AppTheme.color.accent.primary),
                          opacityRange: 0.06...0.55)
                    .frame(width: 400, height: 400)
                if let moodLevel {

                    EchoMoodGlyph(level: moodLevel, size: 18)
                } else {
                    Circle().fill(AppTheme.color.accent.primary).frame(width: 14, height: 14)
                }
            }
            .offset(x: 130)
            .allowsHitTesting(false)
        }
        .clipped()
    }
}

/// Zaman çizelgesi satırı (§5): saat 46 · düğüm 28 · içerik. Düğümler arası dikey çizgiyi satır kendisi çizer.
struct EchoTimelineRow: View {
    nonisolated enum State: Equatable {
        case completed(moodLevel: EchoMoodLevel, moodLabel: String, energyLabel: String?, summary: String, topics: [String])
        case processing(transcript: String?)
        case failed(transcript: String?, canRetry: Bool)
    }

    let time: Date
    let state: State
    var connectsAbove = false
    var connectsBelow = false
    var onRetry: (() -> Void)?
    let onTap: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: onTap) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {

                    VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                        timeLabel
                        HStack(alignment: .top, spacing: AppTheme.space.xs) { node; content }
                    }
                } else {
                    HStack(alignment: .top, spacing: AppTheme.space.xs) {
                        timeLabel.frame(width: 46, alignment: .leading)
                        node
                        content
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppTheme.space.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var timeLabel: some View {
        Text(time, format: .dateTime.hour().minute())
            .echoTextStyle(.subhead)
            .fontWeight(.semibold)
            .monospacedDigit()
            .foregroundStyle(AppTheme.color.content.secondary)
    }

    private var node: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle().fill(connectsAbove ? AppTheme.color.border.default : .clear).frame(width: 1.5, height: 12)
                Spacer(minLength: 28)
                Rectangle().fill(connectsBelow ? AppTheme.color.border.default : .clear).frame(width: 1.5)
            }
            .padding(.vertical, -AppTheme.space.xs)
            VStack {
                nodeGlyph.frame(width: 28, height: 28).background(AppTheme.color.bg.canvas)
                Spacer(minLength: 0)
            }
        }
        .frame(width: 28)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var nodeGlyph: some View {
        switch state {
        case .completed(let level, _, _, _, _):
            ZStack {
                Circle().strokeBorder(level.color.opacity(0.45), lineWidth: 1)
                EchoMoodGlyph(level: level, size: 14)
            }
        case .processing:
            ZStack {
                EchoRippleView(ringCount: 3, intensity: 0.5, speed: 0.55, color: AppTheme.color.accent.primary)
                Circle().fill(AppTheme.color.accent.primary).frame(width: 10, height: 10)
            }
        case .failed:
            ZStack {
                Circle().fill(AppTheme.color.feedback.danger.opacity(0.16))
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.color.feedback.danger)
            }
        }
    }

    @ViewBuilder private var content: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
            switch state {
            case let .completed(_, moodLabel, energyLabel, summary, topics):
                HStack(spacing: AppTheme.space.xxxs) {
                    Text(moodLabel).echoTextStyle(.subhead).fontWeight(.semibold)
                        .foregroundStyle(AppTheme.color.content.primary)
                    if let energyLabel {

                        Text(verbatim: "· " + energyLabel).echoTextStyle(.footnote)
                            .foregroundStyle(AppTheme.color.content.secondary)
                    }
                }
                Text(summary)
                    .echoTextStyle(.entry)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if !topics.isEmpty {

                    Text(topics.prefix(3).joined(separator: " · "))
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            case .processing(let transcript):
                Text("today.timeline.processing")
                    .echoTextStyle(.subhead).fontWeight(.semibold)
                    .foregroundStyle(AppTheme.color.content.accent)
                if let transcript, !transcript.isEmpty {

                    Text("“\(transcript)”")
                        .echoTextStyle(.entryQuote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: AppTheme.space.xxs) {
                    EchoSkeleton(width: 80, height: 6, cornerRadius: 3)
                    EchoSkeleton(width: 48, height: 6, cornerRadius: 3)
                }
                .padding(.top, 2)
            case let .failed(transcript, canRetry):
                Text("today.timeline.failed")
                    .echoTextStyle(.subhead).fontWeight(.semibold)
                    .foregroundStyle(AppTheme.color.feedback.danger)
                if let transcript, !transcript.isEmpty {

                    Text("“\(transcript)”")
                        .echoTextStyle(.entryQuote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                        .lineLimit(2)
                }
                Text("today.timeline.failedBody")
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
                if canRetry, let onRetry {

                    Button(action: onRetry) {
                        Label("today.timeline.retry", systemImage: "arrow.clockwise")
                            .echoTextStyle(.subhead).fontWeight(.semibold)
                            .foregroundStyle(AppTheme.color.feedback.danger)
                            .frame(minHeight: AppTheme.layout.minTouchTarget)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Hedef satırı (§5). Tamamlanmış hedef gün boyunca üstü çizili kalır; tamamlama kararını sunucu verir.
struct EchoChecklistRow: View {
    let title: String
    var detail: String?
    var isCompleted = false
    let onComplete: () -> Void
    var onOpen: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.space.sm) {
            Button(action: onComplete) {
                ZStack {
                    if isCompleted {

                        Circle().fill(AppTheme.color.accent.secondary)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.color.bg.canvas)
                    } else {
                        Circle().strokeBorder(AppTheme.color.border.strong, lineWidth: 1.5)
                    }
                }
                .frame(width: 26, height: 26)
                .frame(width: AppTheme.layout.minTouchTarget, height: AppTheme.layout.minTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)
            .sensoryFeedback(.success, trigger: isCompleted)
            .accessibilityLabel(Text(isCompleted ? "today.goals.a11yDone \(title)" : "today.goals.a11yComplete \(title)"))
            .padding(.leading, -9)

            Button { onOpen?() } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .echoTextStyle(.body)
                        .strikethrough(isCompleted, color: AppTheme.color.content.tertiary)
                        .foregroundStyle(isCompleted ? AppTheme.color.content.secondary : AppTheme.color.content.primary)
                        .multilineTextAlignment(.leading)
                    if let detail {

                        Text(detail)
                            .echoTextStyle(.footnote)
                            .foregroundStyle(AppTheme.color.content.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: AppTheme.layout.listRowMinHeight)
    }
}

/// Geçmişte bugün (§5): solda 64 pt halka + mood şekli, sağda tarih, mood ve serif italik alıntı. Çerçeve yok.
struct PastTodayBlock: View {
    let caption: String
    let moodLevel: EchoMoodLevel
    let moodLabel: String
    let quote: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: AppTheme.space.sm) {
                ZStack {
                    EchoRings(count: 3, baseRadius: 12, step: 9, color: moodLevel.color, opacityRange: 0.12...0.6)
                    EchoMoodGlyph(level: moodLevel, size: 16)
                }
                .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                    Text(caption)
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                    HStack(spacing: AppTheme.space.xxxs) {
                        EchoMoodGlyph(level: moodLevel, size: 11)
                        Text(moodLabel).echoTextStyle(.subhead).fontWeight(.semibold)
                            .foregroundStyle(AppTheme.color.content.primary)
                    }
                    Text("“\(quote)”")
                        .echoTextStyle(.entryQuote)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
