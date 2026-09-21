import SwiftUI

/// Ekran içi kalıcı bilgi/uyarı bloğu (implementation.md §4.12).
nonisolated enum EchoFeedbackKind: Sendable {
    case info
    case success
    case warning
    case danger

    var tint: Color {
        switch self {
        case .info: AppTheme.color.feedback.info
        case .success: AppTheme.color.feedback.success
        case .warning: AppTheme.color.feedback.warning
        case .danger: AppTheme.color.feedback.danger
        }
    }

    var systemImage: String {
        switch self {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "exclamationmark.octagon.fill"
        }
    }
}

struct EchoBanner<Action: View>: View {
    private let kind: EchoFeedbackKind
    private let title: String
    private let message: String?
    private let onDismiss: (() -> Void)?
    private let action: Action

    init(kind: EchoFeedbackKind,
         title: String,
         message: String? = nil,
         onDismiss: (() -> Void)? = nil,
         @ViewBuilder action: () -> Action = { EmptyView() }) {
        self.kind = kind
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
        self.action = action()
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.space.xs) {
            Image(systemName: kind.systemImage)
                .font(.system(size: AppTheme.icon.md, weight: .semibold))
                .foregroundStyle(kind.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                Text(title)
                    .echoTextStyle(.bodyEmphasis)
                    .foregroundStyle(AppTheme.color.content.primary)
                if let message {

                    Text(message)
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
                action
            }
            Spacer(minLength: 0)
            if let onDismiss {

                EchoIconButton("xmark", accessibilityTitle: "common.close", action: onDismiss)
            }
        }
        .padding(AppTheme.space.xs)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous).fill(kind.tint.opacity(0.10)))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous)
                .strokeBorder(kind.tint.opacity(0.35), lineWidth: 1)
        }
    }
}

#Preview("Banner") {
    VStack(spacing: AppTheme.space.sm) {
        EchoBanner(kind: .warning, title: "Bağlantı kurulamadı", message: "Sunucuya ulaşılamıyor. Daha sonra tekrar deneyin.")
        EchoBanner(kind: .info, title: "Analiz sürüyor", message: "Kaydın hazır olduğunda burada görünecek.", onDismiss: {})
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
