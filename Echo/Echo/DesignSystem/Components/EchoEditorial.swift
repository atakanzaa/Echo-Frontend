import SwiftUI

/// Editoryal yerleşim parçaları (implementation.md §2.1): kart yığını yerine tipografi, boşluk ve ince çizgi.
/// Bir ekranda tek vurgulu alan bulunur; diğer her şey sakin kalır.

/// Bölüm etiketi: küçük, büyük harf, geniş aralıklı; sağda opsiyonel metin bağlantısı.
struct EchoSectionLabel: View {
    let title: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .echoTextStyle(.caption2)
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(AppTheme.color.content.tertiary)
            Spacer(minLength: AppTheme.space.xs)
            if let actionTitle, let action {

                Button(action: action) {
                    Text(actionTitle)
                        .echoTextStyle(.subhead)
                        .foregroundStyle(AppTheme.color.content.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, AppTheme.space.xxs)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Günün sorusu: sayfanın tek odağı. Soru sunucunun son yansımasından gelir; dokununca kayıt açılır.
struct EchoQuestionHero: View {
    let question: String
    let actionTitle: LocalizedStringKey
    var secondaryTitle: LocalizedStringKey?
    let onRecord: () -> Void
    var onWrite: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.md) {
            Text(question)
                .font(.system(size: 30, weight: .regular, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(AppTheme.color.content.primary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: AppTheme.space.sm) {
                Button(action: onRecord) {
                    HStack(spacing: AppTheme.space.xs) {
                        ZStack {
                            EchoRippleView(ringCount: 3, intensity: 0.55, speed: 0.7,
                                           color: AppTheme.color.accent.primary, lineWidth: 1.2)
                                .frame(width: 52, height: 52)
                            Circle()
                                .fill(AppTheme.color.accent.primary)
                                .frame(width: 30, height: 30)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.color.content.onAccent)
                        }
                        Text(actionTitle)
                            .echoTextStyle(.headline)
                            .foregroundStyle(AppTheme.color.content.primary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if let secondaryTitle, let onWrite {

                    Text(verbatim: "·").foregroundStyle(AppTheme.color.content.tertiary)
                    Button(action: onWrite) {
                        Text(secondaryTitle)
                            .echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Zaman çizelgesi satırı: solda saat, ortada mood işareti ve serif metin. Kart yok; satırlar çizgiyle ayrılır.
struct EchoTimelineRow: View {
    let time: Date
    let text: String
    var moodLevel: EchoMoodLevel?
    var caption: String?
    var statusText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.space.sm) {
                Text(time, format: .dateTime.hour().minute())
                    .echoTextStyle(.caption)
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.color.content.tertiary)
                    .frame(width: 44, alignment: .leading)
                VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                    HStack(spacing: AppTheme.space.xxs) {
                        if let moodLevel {

                            EchoMoodGlyph(level: moodLevel, size: 10)
                        }
                        if let caption {

                            Text(caption)
                                .echoTextStyle(.caption)
                                .foregroundStyle(AppTheme.color.content.secondary)
                        }
                        if let statusText {

                            Text(statusText)
                                .echoTextStyle(.caption)
                                .foregroundStyle(AppTheme.color.content.accent)
                        }
                    }
                    Text(text)
                        .echoTextStyle(.entry)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, AppTheme.space.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Geçmişten bir alıntı: sol kenarda ince vurgu çizgisi, serif italik metin.
struct EchoQuoteBlock: View {
    let text: String
    let caption: String
    var onTap: (() -> Void)?

    var body: some View {
        Button { onTap?() } label: {
            HStack(alignment: .top, spacing: AppTheme.space.sm) {
                Rectangle()
                    .fill(AppTheme.color.accent.primary.opacity(0.6))
                    .frame(width: 2)
                VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                    Text(text)
                        .echoTextStyle(.entryQuote)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    Text(caption)
                        .echoTextStyle(.caption)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
                Spacer(minLength: 0)
            }
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Hedef satırı: işaretlenebilir daire ve başlık; tamamlama kararını sunucu verir.
struct EchoChecklistRow: View {
    let title: String
    var detail: String?
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.space.sm) {
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(AppTheme.color.border.strong, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                    .frame(width: AppTheme.layout.minTouchTarget, height: AppTheme.layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, -11)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .echoTextStyle(.body)
                    .foregroundStyle(AppTheme.color.content.primary)
                if let detail {

                    Text(detail)
                        .echoTextStyle(.caption)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Satırlar arası ince çizgi; içerik girintisinden başlar.
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

/// Metin bağlantısı gibi davranan satır: ikon yok, kutu yok; sonda ok.
struct EchoLinkRow: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .echoTextStyle(.headline)
                        .foregroundStyle(AppTheme.color.content.primary)
                    if let subtitle {

                        Text(subtitle)
                            .echoTextStyle(.footnote)
                            .foregroundStyle(AppTheme.color.content.secondary)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.color.content.accent)
            }
            .padding(.vertical, AppTheme.space.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
