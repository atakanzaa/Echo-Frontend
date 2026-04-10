import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.Colors.destructive)

            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary(.dark))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)

            if let retryAction {
                Button(action: retryAction) {
                    Text("Retry")
                        .font(AppTheme.Typography.label).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Gradients.accent)
                        .cornerRadius(AppTheme.Spacing.radiusFull)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(AppTheme.Colors.textMuted(.dark))

            Text(title)
                .font(AppTheme.Typography.heading3)
                .foregroundColor(AppTheme.Colors.textPrimary(.dark))

            Text(subtitle)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textMuted(.dark))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
    }
}
