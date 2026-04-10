import SwiftUI
import Combine

struct EchoKnowsYouView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = EchoKnowsYouViewModel()

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: "profile")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    Spacer()
                    Text(locManager.t("profile.ai_profile"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    Spacer()
                    // Invisible spacer for centering
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if let summary = viewModel.profileSummary {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Hero card
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .frame(width: 64, height: 64)
                                    .background(AppTheme.Colors.accent.opacity(0.12))
                                    .cornerRadius(AppTheme.Spacing.radiusFull)

                                Text(locManager.t("profile.ai_profile"))
                                    .font(AppTheme.Typography.heading2)
                                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                                Text(locManager.t("profile.ai_profile_subtitle"))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, AppTheme.Spacing.md)

                            // Sections
                            VStack(spacing: AppTheme.Spacing.md) {
                                if let profile = summary.userProfile, !profile.isEmpty {
                                    AIProfileSection(
                                        icon: "person.text.rectangle",
                                        title: locManager.t("profile.about_you"),
                                        text: profile,
                                        color: AppTheme.Colors.accent
                                    )
                                }

                                if let patterns = summary.emotionalPatterns, !patterns.isEmpty {
                                    AIProfileSection(
                                        icon: "heart.text.square",
                                        title: locManager.t("profile.emotional_patterns"),
                                        text: patterns,
                                        color: AppTheme.Colors.moodVeryPositive
                                    )
                                }

                                if let strengths = summary.valuesStrengths, !strengths.isEmpty {
                                    AIProfileSection(
                                        icon: "star.fill",
                                        title: locManager.t("profile.strengths"),
                                        text: strengths,
                                        color: AppTheme.Colors.gold
                                    )
                                }

                                if let growth = summary.growthTrajectory, !growth.isEmpty {
                                    AIProfileSection(
                                        icon: "chart.line.uptrend.xyaxis",
                                        title: locManager.t("profile.growth"),
                                        text: growth,
                                        color: AppTheme.Colors.success
                                    )
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)

                            // Updated info
                            if let updated = summary.lastUpdated {
                                Text(locManager.t("profile.ai_last_updated") + " " + formatDate(updated))
                                    .font(AppTheme.Typography.micro)
                                    .foregroundColor(AppTheme.Colors.textDisabled(colorScheme))
                                    .padding(.top, AppTheme.Spacing.sm)
                            }

                            Spacer().frame(height: AppTheme.Spacing.xxl)
                        }
                    }
                } else {
                    // No AI profile yet
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        Text(locManager.t("profile.ai_profile_empty"))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    Spacer()
                }
            }
        }
        .onAppear { viewModel.load() }
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateStr) else { return dateStr }
            return relativeFormat(date)
        }
        return relativeFormat(date)
    }

    private func relativeFormat(_ date: Date) -> String {
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - AI Profile Section Card

private struct AIProfileSection: View {
    let icon: String
    let title: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12))
                    .cornerRadius(AppTheme.Spacing.radiusSm)
                Text(title)
                    .font(AppTheme.Typography.bodyEm)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }

            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
    }
}

// MARK: - ViewModel

@MainActor
final class EchoKnowsYouViewModel: ObservableObject {
    @Published var profileSummary: APIProfileSummary?
    @Published var isLoading = false

    func load() {
        guard profileSummary == nil else { return }
        isLoading = true
        Task {
            do {
                let summary: APIProfileSummary = try await APIClient.shared.requestWithAutoRefresh(.profileSummary)
                profileSummary = summary
            } catch {
                profileSummary = nil
            }
            isLoading = false
        }
    }
}
