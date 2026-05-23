import SwiftUI

fileprivate enum GoalBadgeTone {
    case accent
    case success
    case warning
    case neutral

    func foreground(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .accent:
            return AppTheme.Colors.accent
        case .success:
            return AppTheme.Colors.success
        case .warning:
            return AppTheme.Colors.gold
        case .neutral:
            return AppTheme.Colors.textMuted(colorScheme)
        }
    }

    func background(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .accent:
            return AppTheme.Colors.accentSoft(colorScheme)
        case .success:
            return AppTheme.Colors.successSoft(colorScheme)
        case .warning:
            return AppTheme.Colors.goldSoft(colorScheme)
        case .neutral:
            return AppTheme.Colors.surface(colorScheme)
        }
    }
}

struct GoalMetaBadge: View {
    let title: String
    fileprivate let tone: GoalBadgeTone
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.micro)
            .fontWeight(.semibold)
            .foregroundColor(tone.foreground(colorScheme))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(tone.background(colorScheme))
            .cornerRadius(AppTheme.Spacing.radiusFull)
    }
}

struct GoalActionCardView: View {
    let goal: APIGoal
    let isMutating: Bool
    let onComplete: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.title)
                            .font(AppTheme.Typography.bodyEm)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)

                        if let timeframe = goal.timeframe, !timeframe.isEmpty {
                            Text(timeframe)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        }
                    }
                    Spacer(minLength: AppTheme.Spacing.sm)
                    GoalMetaBadge(
                        title: goal.creationType == .ai ? locManager.t("goals.origin.ai") : locManager.t("goals.origin.manual"),
                        tone: goal.creationType == .ai ? .accent : .warning
                    )
                }

                if goal.creationType == .ai {
                    Text(locManager.t("goals.ai_detected_hint"))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Button(action: onComplete) {
                    Text(locManager.t("goal.complete"))
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Gradients.accent)
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                }
                .disabled(isMutating)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.destructive)
                        .frame(width: 48, height: 44)
                        .background(AppTheme.Colors.surface(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                }
                .disabled(isMutating)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
        .opacity(isMutating ? 0.7 : 1.0)
    }
}

struct GoalCompletedCardView: View {
    let goal: APIGoal
    let isMutating: Bool
    let onDelete: () -> Void
    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    private var completionLabel: String {
        goal.completionType == .ai
            ? locManager.t("goals.completed.ai")
            : locManager.t("goals.completed.manual")
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.successSoft(colorScheme))
                    .frame(width: 42, height: 42)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.success)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(goal.title)
                    .font(AppTheme.Typography.bodyEm)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        completionBadges
                    }
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        completionBadges
                    }
                }

                if let completedAt = goal.completedAt, !completedAt.isEmpty {
                    Text(goal.completedTimeLabel)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }

            Spacer(minLength: AppTheme.Spacing.sm)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.destructive)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }
            .disabled(isMutating)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
        .opacity(isMutating ? 0.7 : 1.0)
    }

    @ViewBuilder
    private var completionBadges: some View {
        GoalMetaBadge(
            title: goal.creationType == .ai ? locManager.t("goals.origin.ai") : locManager.t("goals.origin.manual"),
            tone: goal.creationType == .ai ? .accent : .warning
        )
        GoalMetaBadge(title: completionLabel, tone: .success)
    }
}

extension APIGoal {
    var completedTimeLabel: String {
        guard let completedAt, !completedAt.isEmpty else { return "" }
        guard let date = DateFormatting.parseISO8601(completedAt) else { return completedAt }
        return DateFormatting.mediumDate(from: date)
    }
}
