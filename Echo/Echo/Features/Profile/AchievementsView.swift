import SwiftUI

@Observable
@MainActor
private final class AchievementsViewModel {
    private(set) var achievements: Achievements?
    private(set) var isLoading = false
    private(set) var error: AppError?
    @ObservationIgnored private let insights: any InsightsServicing

    init(insights: any InsightsServicing) { self.insights = insights }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do { achievements = try await insights.achievements() }
        catch { self.error = AppError.from(error) }
    }
}

struct AchievementsView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: AchievementsViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.space.xs), count: 3)

    init(insights: any InsightsServicing) {
        _model = State(initialValue: AchievementsViewModel(insights: insights))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.layout.sectionGap) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.load() } }
                    })
                }
                if let achievements = model.achievements {
                    header(achievements)
                    LazyVGrid(columns: columns, spacing: AppTheme.space.sm) {
                        ForEach(achievements.badges) { badge in
                            EchoAchievementTile(model: .init(
                                id: badge.key, title: badge.title, emoji: badge.emoji,
                                isEarned: badge.isEarned, progress: badge.progress,
                                earnedAtText: badge.earnedAt?.formatted(date: .abbreviated, time: .omitted)
                            ), onTap: { router.push(.achievementDetail(badgeKey: badge.key)) })
                        }
                    }
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 260)
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("achievements.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private func header(_ achievements: Achievements) -> some View {
        EchoCard(style: .raised) {
            HStack(spacing: AppTheme.space.md) {
                EchoProgressRing(progress: achievements.totalCount > 0
                    ? Double(achievements.earnedCount) / Double(achievements.totalCount) : 0,
                                 size: 88, label: "\(achievements.earnedCount)/\(achievements.totalCount)")
                VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                    Text(achievements.level).echoTextStyle(.title2).foregroundStyle(AppTheme.color.content.primary)
                    Text(achievements.levelMessage).echoTextStyle(.body).foregroundStyle(AppTheme.color.content.secondary)
                    EchoStreakBadge(text: achievements.streakMessage)
                }
            }
        }
    }
}

@Observable
@MainActor
private final class AchievementDetailViewModel {
    private(set) var detail: AchievementDetail?
    private(set) var isLoading = false
    private(set) var error: AppError?
    private let key: String
    @ObservationIgnored private let insights: any InsightsServicing

    init(key: String, insights: any InsightsServicing) { self.key = key; self.insights = insights }
    func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do { detail = try await insights.achievementDetail(badgeKey: key) }
        catch { self.error = AppError.from(error) }
    }
}

struct AchievementDetailView: View {
    @State private var model: AchievementDetailViewModel

    init(key: String, insights: any InsightsServicing) {
        _model = State(initialValue: AchievementDetailViewModel(key: key, insights: insights))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space.lg) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error))
                }
                if let detail = model.detail {
                    Text(detail.emoji).font(.system(size: 72))
                    Text(detail.title).echoTextStyle(.title1).multilineTextAlignment(.center)
                    Text(detail.description).echoTextStyle(.body).foregroundStyle(AppTheme.color.content.secondary)
                        .multilineTextAlignment(.center)
                    EchoProgressRing(progress: detail.progress, size: 104,
                                     label: detail.progress.formatted(.percent.precision(.fractionLength(0))))
                    Text(detail.criteriaDescription).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.tertiary)
                        .multilineTextAlignment(.center)
                    ShareLink(item: detail.shareText) {
                        Label("common.share", systemImage: "square.and.arrow.up")
                            .echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.accent)
                    }
                } else if model.isLoading {
                    ProgressView().frame(minHeight: 260)
                }
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("achievements.detailTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }
}
