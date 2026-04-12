import SwiftUI

struct AchievementDetailView: View {
    let badge: APIBadge
    let onShare: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var detail: APIAchievementDetail?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    } else {
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.lg) {
                                Text(badge.emoji)
                                    .font(.system(size: 64))
                                    .frame(width: 120, height: 120)
                                    .background(AppTheme.Colors.surfaceElevated(colorScheme))
                                    .cornerRadius(AppTheme.Spacing.radiusLg)

                                Text(badge.title)
                                    .font(AppTheme.Typography.heading2)
                                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                    .multilineTextAlignment(.center)

                                Text(detail?.description ?? "")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                                    .multilineTextAlignment(.center)

                                if !badge.isEarned {
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                        Text(locManager.t("achievements.progress"))
                                            .font(AppTheme.Typography.label)
                                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                        ProgressView(value: max(0, min(detail?.progress ?? 0, 1)))
                                            .tint(AppTheme.Colors.accent)
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.surface(colorScheme))
                                    .cornerRadius(AppTheme.Spacing.radiusMd)
                                }

                                if badge.isEarned {
                                    Button {
                                        let shareText = "\(badge.emoji) \(badge.title)"
                                        onShare(shareText, badge.emoji)
                                        dismiss()
                                    } label: {
                                        Text(locManager.t("achievements.share"))
                                            .font(AppTheme.Typography.bodyEm)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, AppTheme.Spacing.md)
                                            .background(AppTheme.Gradients.accent)
                                            .cornerRadius(AppTheme.Spacing.radiusMd)
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.lg)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(locManager.t("common.cancel")) { dismiss() }
                }
            }
        }
        .task {
            defer { isLoading = false }
            do {
                let loaded: APIAchievementDetail = try await APIClient.shared.requestWithAutoRefresh(
                    .getAchievementDetail(badgeKey: badge.key)
                )
                detail = loaded
            } catch {
                detail = APIAchievementDetail(
                    key: badge.key,
                    title: badge.title,
                    emoji: badge.emoji,
                    description: nil,
                    criteriaDescription: nil,
                    isEarned: badge.isEarned,
                    earnedAt: badge.earnedAt,
                    progress: badge.isEarned ? 1 : 0,
                    shareText: nil
                )
            }
        }
    }
}
