import SwiftUI

/// Bugün ekranının blok bileşenleri (HANDOFF §5). Tüm değerler sunucudan gelir; bileşenler yalnız biçimlendirir.

/// Günün girişi: tarih + zil, selam, seri satırı.
struct TodayHeader: View {
    let dateText: String
    let greeting: String
    let streakDays: Int
    let recordedToday: Bool
    /// Bugünün kayıt sayısı sunucunun takviminden gelir; liste sayılmaz.
    let todayEntryCount: Int?
    let unreadCount: Int
    let onNotifications: () -> Void
    let onStreak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            HStack(alignment: .center) {
                Text(dateText)
                    .echoTextStyle(.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.color.content.secondary)
                Spacer()
                bell
            }
            Text(greeting)
                .echoTextStyle(.display)
                .foregroundStyle(AppTheme.color.content.primary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onStreak) {
                HStack(spacing: AppTheme.space.xxs) {
                    streakGlyph
                    (streakText + Text(verbatim: " · ").foregroundColor(AppTheme.color.content.tertiary) + statusText)
                        .echoTextStyle(.subhead)
                        .multilineTextAlignment(.leading)
                }
                .frame(minHeight: AppTheme.layout.minTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var bell: some View {
        Button(action: onNotifications) {
            Image(systemName: "bell")
                .font(.system(size: AppTheme.icon.md, weight: .medium))
                .foregroundStyle(AppTheme.color.content.primary)
                .frame(width: AppTheme.layout.minTouchTarget, height: AppTheme.layout.minTouchTarget)
                .background(Circle().fill(AppTheme.color.bg.surface))
                .overlay(alignment: .topTrailing) {
                    if unreadCount > 0 {

                        Text(verbatim: unreadCount > 99 ? "99+" : "\(unreadCount)")
                            .font(.system(size: 11, weight: .bold)).monospacedDigit()
                            .foregroundStyle(AppTheme.color.bg.canvas)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Capsule().fill(AppTheme.color.feedback.danger))
                            .offset(x: 4, y: -4)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(unreadCount > 0 ? "today.bell.a11yUnread \(unreadCount)" : "notifications.title"))
    }

    /// Seri glifi: ilk gün kesikli, bugün kayıt yoksa iç halka boş, kayıt varsa iç daire akuamarin.
    private var streakGlyph: some View {
        ZStack {
            EchoRings(count: 2, baseRadius: 4.5, step: 3.5,
                      color: streakDays == 0 ? AppTheme.color.content.tertiary : AppTheme.color.content.accent,
                      opacityRange: 0.5...0.9, lineWidth: 1.2, dashed: streakDays == 0)
            if recordedToday {

                Circle().fill(AppTheme.color.accent.secondary).frame(width: 6, height: 6)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }

    private var streakText: Text {
        if streakDays == 0 { return Text("today.status.firstDay").fontWeight(.semibold).foregroundColor(AppTheme.color.content.primary) }
        return Text(String(format: String(localized: "today.streak.days"), streakDays))
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.color.content.primary)
    }

    private var statusText: Text {
        if let count = todayEntryCount, count > 0 {

            return Text(String(format: String(localized: "today.status.count"), count)).foregroundColor(AppTheme.color.content.secondary)
        }
        return Text("today.status.none").foregroundColor(AppTheme.color.content.secondary)
    }
}

/// Kapsül satırı: açılabilir kapsül varsa amber vurgulu, yoksa sıradaki açılış tarihi; ikisi de yoksa gösterilmez.
struct CapsuleRow: View {
    let openableCount: Int
    let nextUnlockText: String?
    let onTap: () -> Void

    var body: some View {
        if openableCount > 0 {

            Button(action: onTap) {
                HStack(spacing: AppTheme.space.xs) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.color.bg.canvas)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(EchoPrimitive.amber500))
                    Text(String(format: String(localized: "today.capsule.openable"), openableCount))
                        .echoTextStyle(.subhead).fontWeight(.semibold)
                        .foregroundStyle(AppTheme.color.content.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: AppTheme.space.xxs)
                    HStack(spacing: 2) {
                        Text("today.capsule.open").echoTextStyle(.subhead).fontWeight(.semibold)
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.color.feedback.warning)
                }
                .padding(.horizontal, AppTheme.space.xs)
                .frame(minHeight: 52)
                .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous)
                    .fill(EchoPrimitive.amber500.opacity(0.12)))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else if let nextUnlockText {

            Button(action: onTap) {
                VStack(spacing: 0) {
                    EchoHairline()
                    HStack(spacing: AppTheme.space.xs) {
                        Image(systemName: "pills")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.color.feedback.warning)
                        Text(String(format: String(localized: "today.capsule.next"), nextUnlockText))
                            .echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.secondary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.color.content.tertiary)
                    }
                    .frame(minHeight: 52)
                    EchoHairline()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// AI hedef önerisi: menekşe yumuşak zemin, iki metin butonu; metinler sunucudan.
struct GoalSuggestionRow: View {
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.space.xs) {
            EchoRings(count: 2, baseRadius: 4, step: 4, color: AppTheme.color.content.accent, opacityRange: 0.45...0.9)
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                Text(message).echoTextStyle(.subhead)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: AppTheme.space.md) {
                    Button(action: onAccept) {
                        Text(primaryTitle).echoTextStyle(.subhead).fontWeight(.semibold)
                            .foregroundStyle(AppTheme.color.content.accent)
                            .frame(minHeight: AppTheme.layout.minTouchTarget)
                    }
                    Button(action: onReject) {
                        Text(secondaryTitle).echoTextStyle(.subhead)
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .frame(minHeight: AppTheme.layout.minTouchTarget)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous).fill(AppTheme.color.bg.accentSoft))
    }
}

/// Rozet ilerleme halkası: iz halkası, amber ilerleme yayı ve ortada rozet emojisi.
struct BadgeProgressRing: View {
    let emoji: String
    let progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(EchoPrimitive.amber500.opacity(0.18), lineWidth: 1).frame(width: 64, height: 64)
            Circle().stroke(AppTheme.color.border.subtle, lineWidth: 5).frame(width: 54, height: 54)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(EchoPrimitive.amber500, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 54, height: 54)
            Text(emoji).font(.system(size: 24))
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }
}

/// İlerleme bölümü: sunucunun streak cümlesi, sıradaki rozet ve toplamlar.
struct ProgressSection: View {
    let streakMessage: String
    var badgeEmoji: String?
    var badgeTitle: String?
    var badgeProgress: Double?
    var badgeRemainingText: String?
    var earnedText: String?
    var statsText: String?
    var onBadge: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.sm) {
            Text(streakMessage)
                .echoTextStyle(.headline)
                .fontWeight(.regular)
                .foregroundStyle(AppTheme.color.content.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let badgeTitle, let badgeProgress, let badgeEmoji {

                Button { onBadge?() } label: {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppTheme.space.sm) { ring(badgeEmoji, badgeProgress); badgeText(badgeTitle, badgeProgress); Spacer(); chevron }
                        VStack(alignment: .leading, spacing: AppTheme.space.xs) { ring(badgeEmoji, badgeProgress); badgeText(badgeTitle, badgeProgress) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let statsText {

                Text(statsText).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
            }
        }
    }

    private func ring(_ emoji: String, _ progress: Double) -> some View {
        BadgeProgressRing(emoji: emoji, progress: progress)
    }

    private func badgeText(_ title: String, _ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(earnedText.map { String(localized: "today.progress.nextBadge") + " · " + $0 } ?? String(localized: "today.progress.nextBadge"))
                .echoTextStyle(.footnote).fontWeight(.semibold)
                .foregroundStyle(AppTheme.color.content.secondary)
            Text(title).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
            HStack(spacing: 4) {
                if progress > 0 {

                    Text(progress, format: .percent.precision(.fractionLength(0)))
                    if let badgeRemainingText { Text(verbatim: "· " + badgeRemainingText) }
                } else if let badgeRemainingText {

                    Text(badgeRemainingText)
                }
            }
            .echoTextStyle(.footnote).fontWeight(.semibold)
            .foregroundStyle(AppTheme.color.feedback.warning)
        }
        .accessibilityElement(children: .combine)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.color.content.tertiary)
    }
}

/// "Echo seni tanıyor" alıntısı ve koç satırı. Profil yoksa yalnız koç satırı görünür.
struct KnowsYouCoachBlock: View {
    var knowsYou: String?
    let coachTitle: LocalizedStringKey
    var coachSubtitle: String?
    let onCoach: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.sm) {
            if let knowsYou {

                HStack(spacing: AppTheme.space.xxs) {
                    EchoRings(count: 2, baseRadius: 3, step: 4, color: AppTheme.color.accent.secondary, opacityRange: 0.4...0.9)
                        .frame(width: 16, height: 16)
                    Text("today.knowsYou").echoTextStyle(.footnote).fontWeight(.semibold)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
                Text(knowsYou)
                    .echoTextStyle(.entry)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onCoach) {
                HStack(spacing: AppTheme.space.sm) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.color.content.accent)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppTheme.color.bg.accentSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(coachTitle).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
                        if let coachSubtitle {

                            Text(coachSubtitle).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
                .padding(.horizontal, AppTheme.space.sm)
                .frame(minHeight: 68)
                .background(RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous)
                    .strokeBorder(AppTheme.color.border.default, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Çevrimdışı şeridi: son başarılı yüklemenin verisi gösterilir, içerik silinmez.
struct OfflineStrip: View {
    let sinceText: String?
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.space.xs) {
            Image(systemName: "wifi.slash").font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.color.feedback.danger)
            (Text("today.offline").fontWeight(.semibold)
             + Text(verbatim: sinceText.map { " · " + String(format: String(localized: "today.offline.since"), $0) } ?? ""))
                .echoTextStyle(.footnote)
                .foregroundStyle(AppTheme.color.content.primary)
                .lineLimit(2)
            Spacer(minLength: AppTheme.space.xxs)
            Button(action: onRefresh) {
                Label("common.refresh", systemImage: "arrow.clockwise")
                    .echoTextStyle(.footnote).fontWeight(.semibold)
                    .foregroundStyle(AppTheme.color.feedback.danger)
                    .frame(minHeight: AppTheme.layout.minTouchTarget)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.space.sm)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous)
            .fill(AppTheme.color.feedback.danger.opacity(0.14)))
    }
}
