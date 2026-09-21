import SwiftUI

/// "5 sa 12 dk sonra yenilenir". An sunucunun `resets_at` değeridir; uygulama yalnız kalan süreyi biçimlendirir.
struct UsageCountdown: View {
    let resetsAt: Date
    var format: LocalizedStringResource = "usage.renewsIn"

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in

            Text(String(format: String(localized: format), Self.remaining(until: resetsAt, from: context.date)))
        }
    }

    static func remaining(until end: Date, from now: Date) -> String {
        let seconds = max(60, end.timeIntervalSince(now).rounded(.up))
        return Duration.seconds(seconds)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
    }
}

/// Doluluk çubuğu; renk durumu anlatır, yüzde metni yanında ayrıca yazılır.
struct UsageBar: View {
    let percent: Int
    let state: AIUsage.State

    var body: some View {
        GeometryReader { proxy in

            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.color.bg.surfaceSunken)
                Capsule().fill(color)
                    .frame(width: proxy.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }

    private var color: Color {
        switch state {
        case .exhausted: AppTheme.color.feedback.danger
        case .warning: AppTheme.color.feedback.warning
        case .ok, .unknown: AppTheme.color.accent.primary
        }
    }
}

/// Uyarı ya da hak bitti şeridi. Metin sunucunun mesajıdır; premium teklifi `offer_upgrade` ile açılır.
struct UsageNotice: View {
    let usage: AIUsage
    /// Kayıt ekranında, hak bitse de kaydın saklandığını söyleyen satır eklenir.
    var isRecording = false
    var onUpgrade: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.space.xs) {
                Image(systemName: usage.state == .exhausted ? "hourglass" : "gauge.with.dots.needle.67percent")
                    .foregroundStyle(usage.state == .exhausted ? AppTheme.color.feedback.danger : AppTheme.color.feedback.warning)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                    if let message = usage.message {

                        Text(message)
                            .echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if isRecording, usage.state == .exhausted {

                        Text("usage.recordingStillSaved")
                            .echoTextStyle(.footnote)
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    UsageCountdown(resetsAt: usage.resetsAt)
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
            if usage.offerUpgrade, let onUpgrade {

                Button(action: onUpgrade) {
                    Text("usage.upgrade")
                        .echoTextStyle(.subhead).fontWeight(.semibold)
                        .foregroundStyle(AppTheme.color.content.accent)
                        .frame(minHeight: AppTheme.layout.minTouchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous).fill(AppTheme.color.bg.surface))
        .accessibilityElement(children: .combine)
    }
}
