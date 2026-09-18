import SwiftUI

/// Boş durum (implementation.md §4.28). Veri yokluğu sıfır değeriyle değil bu bileşenle anlatılır.
struct EchoEmptyState<Action: View>: View {
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey?
    private let systemImage: String
    private let action: Action

    init(_ title: LocalizedStringKey,
         message: LocalizedStringKey? = nil,
         systemImage: String = "circle.hexagongrid",
         @ViewBuilder action: () -> Action = { EmptyView() }) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action()
    }

    var body: some View {
        VStack(spacing: AppTheme.space.sm) {
            EchoRippleMark(systemImage: systemImage)
            Text(title)
                .echoTextStyle(.title3)
                .foregroundStyle(AppTheme.color.content.primary)
                .multilineTextAlignment(.center)
            if let message {

                Text(message)
                    .echoTextStyle(.callout)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .multilineTextAlignment(.center)
            }
            action
        }
        .frame(maxWidth: AppTheme.layout.emptyStateMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(AppTheme.space.lg)
    }
}

/// Echo motifi: eş merkezli halkalar (implementation.md §2.2). Hareket yok; statik işaret.
struct EchoRippleMark: View {
    var systemImage: String = "circle.hexagongrid"
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in

                Circle()
                    .strokeBorder(AppTheme.color.accent.primary.opacity(0.35 - Double(index) * 0.10), lineWidth: 1.5)
                    .frame(width: size - CGFloat(index) * 28, height: size - CGFloat(index) * 28)
            }
            Image(systemName: systemImage)
                .font(.system(size: size / 3.5, weight: .light))
                .foregroundStyle(AppTheme.color.content.accent)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Boş durum") {
    EchoEmptyState("Henüz kayıt yok", message: "İlk günlüğünü kaydettiğinde burada görünecek.", systemImage: "mic") {
        EchoButton(verbatimTitle: "Kayda başla", variant: .secondary) {}
    }
    .background(AppTheme.color.bg.canvas)
}
