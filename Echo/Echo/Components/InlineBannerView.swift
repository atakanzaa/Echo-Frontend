import SwiftUI

struct InlineBannerView: View {
    enum BannerType {
        case error
        case info

        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .error: return AppTheme.Colors.destructive
            case .info: return AppTheme.Colors.accent
            }
        }
    }

    let message: String
    var type: BannerType = .info
    var onDismiss: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(type.color)

            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))

            Spacer(minLength: 0)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(type.color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                .stroke(type.color.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Spacing.radiusMd)
    }
}
