import SwiftUI

/// 4 sekme + merkezde yükseltilmiş kayıt butonu (implementation.md §4.9).
struct EchoTabBar: View {
    @Binding var selection: AppTab
    let isRecording: Bool
    let onRecordTap: () -> Void
    var onReselect: ((AppTab) -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var leadingTabs: [AppTab] { [.today, .journal] }
    private var trailingTabs: [AppTab] { [.community, .profile] }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leadingTabs) { tab in

                item(tab)
            }
            recordButton
                .frame(maxWidth: .infinity)
            ForEach(trailingTabs) { tab in

                item(tab)
            }
        }
        .frame(height: AppTheme.layout.tabBarHeight)
        .padding(.horizontal, AppTheme.space.xxs)
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(AppTheme.color.border.subtle).frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func item(_ tab: AppTab) -> some View {
        Button {
            if selection == tab {

                onReselect?(tab)
            } else {
                selection = tab
            }
        } label: {
            VStack(spacing: AppTheme.space.xxxxs) {
                Image(systemName: selection == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: AppTheme.icon.lg, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                Text(tab.title).echoTextStyle(.caption2)
                Circle()
                    .fill(selection == tab ? AppTheme.color.content.accent : .clear)
                    .frame(width: 4, height: 4)
            }
            .foregroundStyle(selection == tab ? AppTheme.color.content.accent : AppTheme.color.content.tertiary)
            .frame(maxWidth: .infinity, minHeight: AppTheme.layout.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
    }

    /// Kayıt aktifken buton "durdur" biçimine döner ve etrafında halka belirir.
    private var recordButton: some View {
        Button(action: onRecordTap) {
            ZStack {
                if isRecording {

                    Circle()
                        .strokeBorder(AppTheme.color.accent.secondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 74, height: 74)
                }
                Circle()
                    .fill(AppTheme.gradient.auroraRecord)
                    .frame(width: 58, height: 58)
                    .shadow(color: EchoPrimitive.violet700.opacity(0.35), radius: 14, y: 8)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.color.content.onAccent)
            }
            .frame(width: 74, height: 74)
            .contentShape(Circle())
            .offset(y: -8)
            .animation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion), value: isRecording)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("tabs.record"))
    }
}

#Preview("Sekme çubuğu") {
    @Previewable @State var tab = AppTab.today

    return VStack {
        Spacer()
        EchoTabBar(selection: $tab, isRecording: false, onRecordTap: {})
    }
    .background(AppTheme.color.bg.canvas)
}
