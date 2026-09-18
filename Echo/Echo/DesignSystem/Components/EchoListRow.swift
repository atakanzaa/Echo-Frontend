import SwiftUI

/// Liste satırı (implementation.md §4.5). Ayraç leading içeriğin bittiği yerden başlar.
struct EchoListRow<Leading: View, Trailing: View>: View {
    private let title: LocalizedStringKey
    private let subtitle: LocalizedStringKey?
    private let leading: Leading
    private let trailing: Trailing

    init(_ title: LocalizedStringKey,
         subtitle: LocalizedStringKey? = nil,
         @ViewBuilder leading: () -> Leading = { EmptyView() },
         @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: AppTheme.space.xs) {
            leading
            VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
                Text(title)
                    .echoTextStyle(.body)
                    .foregroundStyle(AppTheme.color.content.primary)
                if let subtitle {

                    Text(subtitle)
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
            }
            Spacer(minLength: AppTheme.space.xs)
            trailing
        }
        .padding(.horizontal, AppTheme.space.sm)
        .padding(.vertical, AppTheme.space.xs)
        .frame(minHeight: AppTheme.layout.listRowMinHeight)
        .contentShape(Rectangle())
    }
}

extension View {
    /// Satırı basılabilir yapar; görsel stil değişmez. Dokunma alanı satırın tamamıdır.
    func echoRowButton(action: @escaping () -> Void) -> some View {
        Button(action: action) { self }.buttonStyle(.plain)
    }
}

/// Satır başında yumuşak zeminli ikon.
struct EchoListRowIcon: View {
    let systemImage: String
    var tint: Color = AppTheme.color.content.accent

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: AppTheme.icon.md, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(RoundedRectangle(cornerRadius: AppTheme.radius.sm, style: .continuous).fill(AppTheme.color.bg.accentSoft))
            .accessibilityHidden(true)
    }
}

/// Satır sonunda chevron.
struct EchoDisclosureIndicator: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.color.content.tertiary)
            .accessibilityHidden(true)
    }
}

#Preview("Liste satırları") {
    VStack(spacing: 0) {
        EchoListRow("Bildirimler", subtitle: "Günlük hatırlatma 20:00") {
            EchoListRowIcon(systemImage: "bell")
        } trailing: {
            EchoDisclosureIndicator()
        }
        .echoRowButton {}
        EchoDivider(insetLeading: 60)
        EchoListRow("Karanlık tema") {
            EchoListRowIcon(systemImage: "moon")
        } trailing: {
            Text(verbatim: "Sistem").echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.secondary)
        }
    }
    .background(AppTheme.color.bg.surface)
    .padding()
    .background(AppTheme.color.bg.canvas)
}
