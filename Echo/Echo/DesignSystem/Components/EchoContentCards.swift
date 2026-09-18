import SwiftUI

/// İçgörü kartı (implementation.md §4.24). Başlık ve gövde sunucudan gelir.
struct EchoInsightCard: View {
    let title: String
    let message: String
    var systemImage: String = "sparkles"
    var categoryLabel: String?
    var onShare: (() -> Void)?

    var body: some View {
        EchoCard(style: .raised) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                HStack(spacing: AppTheme.space.xxs) {
                    Image(systemName: systemImage)
                        .font(.system(size: AppTheme.icon.md, weight: .medium))
                        .foregroundStyle(AppTheme.color.content.accent)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: AppTheme.radius.sm, style: .continuous)
                            .fill(AppTheme.color.bg.accentSoft))
                    if let categoryLabel {

                        Text(categoryLabel)
                            .echoTextStyle(.caption2)
                            .textCase(.uppercase)
                            .foregroundStyle(AppTheme.color.content.tertiary)
                    }
                    Spacer(minLength: 0)
                }
                Text(title)
                    .echoTextStyle(.title3)
                    .foregroundStyle(AppTheme.color.content.primary)
                Text(message)
                    .echoTextStyle(.body)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let onShare {

                    EchoButton("common.share", variant: .ghost, size: .sm, leadingIcon: "square.and.arrow.up", action: onShare)
                }
            }
        }
    }
}

/// Haftalık rapor kartı (§4.25).
struct EchoWeeklyReportCard: View {
    let title: String
    let dateRangeText: String
    let summary: String
    let points: [EchoMoodPoint]
    let topics: [String]
    var onOpen: (() -> Void)?

    var body: some View {
        EchoCard(style: .raised, padding: AppTheme.layout.cardPaddingRoomy) {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                HStack(alignment: .top, spacing: AppTheme.space.xs) {
                    EchoRippleView(ringCount: 3, intensity: 0.5, isAnimating: false)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).echoTextStyle(.title2).foregroundStyle(AppTheme.color.content.primary)
                        Text(dateRangeText).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.tertiary)
                    }
                    Spacer(minLength: 0)
                }
                Text(summary)
                    .echoTextStyle(.entry)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                EchoMoodChart(points: points, isCompact: true)
                if !topics.isEmpty {

                    EchoWrapRow(items: topics) { topic in

                        EchoChip(topic)
                    }
                }
                if let onOpen {

                    EchoButton("insights.openFullReport", variant: .ghost, size: .sm, trailingIcon: "chevron.right", action: onOpen)
                }
            }
        }
    }
}

/// Rehberli günlük önerisi (§4.22). Metin sunucudan gelen `reflective_question` olabilir.
struct EchoPromptCard: View {
    let question: String
    var categoryLabel: String?
    var onTap: (() -> Void)?

    var body: some View {
        EchoInteractiveCard(style: .flat, action: { onTap?() }) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                if let categoryLabel {

                    EchoChip(categoryLabel)
                }
                Text(question)
                    .echoTextStyle(.title3)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: AppTheme.icon.sm, weight: .semibold))
                        .foregroundStyle(AppTheme.color.content.accent)
                }
            }
        }
        .frame(width: 280)
    }
}

/// Abonelik planı kartı (§4.30). Fiyat StoreKit'ten, plan bilgisi sunucudan gelir.
struct EchoPlanCard: View {
    let planName: String
    let priceText: String
    let periodText: String
    var savingText: String?
    var isHighlighted: Bool = false
    var isSelected: Bool = false
    var onSelect: (() -> Void)?

    var body: some View {
        Button { onSelect?() } label: {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                if isHighlighted, let savingText {

                    Text(savingText)
                        .echoTextStyle(.caption2)
                        .foregroundStyle(EchoPrimitive.amber700)
                        .padding(.horizontal, AppTheme.space.xxs)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(EchoPrimitive.amber100))
                }
                HStack {
                    Text(planName).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
                    Spacer()
                    if isSelected {

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.color.content.accent)
                    }
                }
                Text(priceText).echoTextStyle(.numeric).foregroundStyle(AppTheme.color.content.primary)
                Text(periodText).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.tertiary)
            }
            .padding(AppTheme.layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous)
                .fill(isSelected ? AppTheme.color.bg.accentSoft : AppTheme.color.bg.surface))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.color.border.accent : AppTheme.color.border.subtle,
                                  lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Onboarding ilerleme çubuğu (§4.31).
struct EchoOnboardingProgress: View {
    let step: Int
    let total: Int
    var onBack: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppTheme.space.xs) {
            if let onBack {

                EchoIconButton("chevron.left", accessibilityTitle: "common.back", action: onBack)
            }
            GeometryReader { proxy in

                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.color.border.subtle)
                    Capsule()
                        .fill(AppTheme.color.accent.primary)
                        .frame(width: proxy.size.width * ratio)
                        .animation(AppTheme.motion.resolved(AppTheme.motion.smooth, reduceMotion: reduceMotion), value: ratio)
                }
            }
            .frame(height: 4)
            Text(verbatim: "\(step) / \(total)")
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var ratio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(min(max(step, 0), total)) / CGFloat(total)
    }
}

/// Satır sonunda alta kayan basit sarmalayıcı dizilim (chip bulutu için).
struct EchoWrapRow<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: AppTheme.space.xxs) {
            ForEach(items, id: \.self) { item in

                content(item)
            }
        }
    }
}

/// Basit akış yerleşimi: sığmayan öğe alt satıra geçer.
nonisolated struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: CGFloat = 1
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        for subview in subviews {

            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {

                rows += 1
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: proposal.width ?? x, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {

            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {

                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("İçerik kartları") {
    ScrollView {
        VStack(spacing: AppTheme.space.sm) {
            EchoInsightCard(title: "Akşamları daha sakinsin",
                            message: "Son yedi günün beşinde akşam kayıtların sabahtan daha olumlu.",
                            categoryLabel: "Örüntü", onShare: {})
            EchoWeeklyReportCard(title: "Bu hafta", dateRangeText: "12–18 Eylül",
                                 summary: "Yedi kayıt bıraktın. Genel ton dengeli görünüyor.",
                                 points: EchoMockData.moodPoints, topics: ["uyku", "iş", "yürüyüş"], onOpen: {})
            EchoPromptCard(question: "Bugün seni ne rahatlattı?", categoryLabel: "Yansıma", onTap: {})
            EchoPlanCard(planName: "Yıllık", priceText: "₺499", periodText: "yılda bir kez",
                         savingText: "En popüler", isHighlighted: true, isSelected: true, onSelect: {})
            EchoOnboardingProgress(step: 4, total: 6, onBack: {})
        }
        .padding()
    }
    .background(AppTheme.color.bg.canvas)
}
