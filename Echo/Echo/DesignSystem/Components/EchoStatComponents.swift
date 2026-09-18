import SwiftUI

/// Sayı kutusu (implementation.md §4.27). Değer ve etiket sunucudan gelir; trend oku yalnız sunucu verirse gösterilir.
struct EchoStatTile: View {
    let value: String
    let label: String
    var trend: Trend?

    nonisolated enum Trend: Sendable {
        case up
        case down

        var systemImage: String { self == .up ? "arrow.up.right" : "arrow.down.right" }
        var color: Color { self == .up ? AppTheme.color.accent.secondary : AppTheme.color.feedback.danger }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
            HStack(spacing: AppTheme.space.xxxs) {
                Text(value)
                    .echoTextStyle(.numeric)
                    .foregroundStyle(AppTheme.color.content.primary)
                if let trend {

                    Image(systemName: trend.systemImage)
                        .font(.system(size: AppTheme.icon.sm, weight: .bold))
                        .foregroundStyle(trend.color)
                }
            }
            Text(label)
                .echoTextStyle(.caption2)
                .foregroundStyle(AppTheme.color.content.tertiary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.layout.cardPaddingCompact)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous).fill(AppTheme.color.bg.surfaceSunken))
        .accessibilityElement(children: .combine)
    }
}

/// İlerleme halkası (§4.14). Değer 0–1 aralığında sunucudan gelir.
struct EchoProgressRing: View {
    let progress: Double
    var size: CGFloat = 56
    var label: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.color.border.subtle, lineWidth: size / 10)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AppTheme.color.accent.primary, style: StrokeStyle(lineWidth: size / 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.motion.resolved(AppTheme.motion.smooth, reduceMotion: reduceMotion), value: progress)
            if let label {

                Text(label)
                    .echoTextStyle(size >= 88 ? .numeric : .caption)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .monospacedDigit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityValue(Text(label ?? ""))
    }
}

/// Streak rozeti (§4.15). Sayı ve metin sunucudan gelir; "aktif mi" kararı istemcide verilmez.
struct EchoStreakBadge: View {
    let text: String
    var isCelebrating: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: AppTheme.space.xxxs) {
            EchoRippleView(ringCount: 2, intensity: 0.7, color: AppTheme.color.content.onAccent, isAnimating: isCelebrating)
                .frame(width: 16, height: 16)
            Text(text)
                .echoTextStyle(.subhead)
                .foregroundStyle(AppTheme.color.content.onAccent)
                .monospacedDigit()
        }
        .padding(.horizontal, AppTheme.space.xs)
        .padding(.vertical, AppTheme.space.xxxs)
        .background(Capsule().fill(AppTheme.gradient.auroraCelebration))
        .scaleEffect(scale)
        .onChange(of: text) { _, _ in

            guard isCelebrating, !reduceMotion else { return }
            withAnimation(AppTheme.motion.bouncy) { scale = 1.18 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(AppTheme.motion.bouncy) { scale = 1 }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Başarım hücresi (§4.26). Kilit durumu ve ilerleme sunucudan gelir.
struct EchoAchievementTile: View {
    nonisolated struct Model: Identifiable, Sendable, Equatable {
        let id: String
        let title: String
        let emoji: String
        let isEarned: Bool
        /// 0–1 aralığında sunucu ilerlemesi.
        let progress: Double
        let earnedAtText: String?
    }

    let model: Model
    var onTap: (() -> Void)?

    var body: some View {
        Button { onTap?() } label: {
            VStack(spacing: AppTheme.space.xxs) {
                ZStack {
                    Circle()
                        .fill(model.isEarned ? AppTheme.color.bg.accentSoft : AppTheme.color.bg.surfaceSunken)
                        .frame(width: 56, height: 56)
                    Text(model.emoji)
                        .font(.system(size: 26))
                        .grayscale(model.isEarned ? 0 : 1)
                        .opacity(model.isEarned ? 1 : 0.45)
                    if !model.isEarned {

                        EchoProgressRing(progress: model.progress, size: 64)
                    }
                }
                Text(model.title)
                    .echoTextStyle(.caption)
                    .foregroundStyle(model.isEarned ? AppTheme.color.content.primary : AppTheme.color.content.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let earnedAtText = model.earnedAtText {

                    Text(earnedAtText)
                        .echoTextStyle(.caption2)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.space.xs)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview("İstatistik bileşenleri") {
    VStack(spacing: AppTheme.space.lg) {
        HStack(spacing: AppTheme.space.xs) {
            EchoStatTile(value: "12", label: "Toplam kayıt")
            EchoStatTile(value: "5", label: "Güncel seri", trend: .up)
            EchoStatTile(value: "0,64", label: "Ortalama mood")
        }
        HStack(spacing: AppTheme.space.lg) {
            EchoProgressRing(progress: 0.42, size: 88, label: "42%")
            EchoStreakBadge(text: "5 gün")
        }
        HStack {
            EchoAchievementTile(model: EchoMockData.earnedBadge)
            EchoAchievementTile(model: EchoMockData.lockedBadge)
        }
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
