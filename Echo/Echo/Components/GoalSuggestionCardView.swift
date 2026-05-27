import SwiftUI

struct GoalSuggestionCardView: View {
    let suggestion: APIGoalSuggestion
    let isLoading: Bool
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: suggestion.suggestionType == AppConstants.GoalSuggestionType.completeGoalConfirm ? "checkmark.seal.fill" : "target")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                Text(suggestion.message)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let reason = suggestion.reason, !reason.isEmpty {
                Text(reason)
                    .font(AppTheme.Typography.micro)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    .lineSpacing(2)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Button(action: onPrimary) {
                    Text(suggestion.primaryActionLabel)
                        .font(AppTheme.Typography.label)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Gradients.accent)
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                }
                .disabled(isLoading)

                Button(action: onSecondary) {
                    Text(suggestion.secondaryActionLabel)
                        .font(AppTheme.Typography.label)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.surface(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                }
                .disabled(isLoading)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    .scaleEffect(0.85)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
        .opacity(isLoading ? 0.75 : 1)
    }
}
