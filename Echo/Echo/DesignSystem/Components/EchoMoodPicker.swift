import SwiftUI
import UIKit

/// Mood seçici (implementation.md §4.18). Sunucuda kullanıcı mood alanı olana kadar
/// yalnız yerel gösterimlerde kullanılır; seçim sunucuya karar olarak gönderilmez.
struct EchoMoodPicker: View {
    @Binding var selection: EchoMoodLevel?
    var labels: [EchoMoodLevel: String] = [:]
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: isCompact ? AppTheme.space.xxs : AppTheme.space.xs) {
            ForEach(EchoMoodLevel.allCases) { level in

                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selection = selection == level ? nil : level
                } label: {
                    VStack(spacing: AppTheme.space.xxxs) {
                        EchoMoodGlyph(level: level, size: isCompact ? 18 : 28, isFilled: selection == level)
                            .scaleEffect(selection == level ? 1.15 : 1)
                        if !isCompact, let label = labels[level] {

                            Text(label)
                                .echoTextStyle(.caption2)
                                .foregroundStyle(selection == level ? AppTheme.color.content.accent : AppTheme.color.content.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: isCompact ? 32 : 56, height: isCompact ? 32 : 72)
                    .background {
                        if selection == level {

                            Capsule().fill(AppTheme.color.bg.accentSoft)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(labels[level] ?? ""))
                .accessibilityAddTraits(selection == level ? [.isSelected] : [])
            }
        }
        .animation(AppTheme.motion.snappy, value: selection)
    }
}

#Preview("Mood seçici") {
    @Previewable @State var selection: EchoMoodLevel? = .good

    return VStack(spacing: AppTheme.space.lg) {
        EchoMoodPicker(selection: $selection, labels: [
            .heavy: "Ağır", .low: "Düşük", .neutral: "Nötr", .good: "İyi", .bright: "Parlak"
        ])
        EchoMoodPicker(selection: $selection, isCompact: true)
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
