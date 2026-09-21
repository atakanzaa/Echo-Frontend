import SwiftUI

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router

    private var user: AuthenticatedUser? { environment.session.state.user }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.layout.sectionGap) {
                if let user {
                    profileHeader(user)
                    stats(user)
                    navigationSections
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("profile.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("profile.edit") { router.push(.editProfile) }
            }
        }
        .refreshable {
            await environment.session.refreshUser()
        }
    }

    /// Profil başlığı: avatar, ad ve e-posta; dekoratif katman yok.
    private func profileHeader(_ user: AuthenticatedUser) -> some View {
        HStack(spacing: AppTheme.space.sm) {
            EchoAvatar(name: user.displayName ?? user.email, size: .lg, hasStreakRing: user.recordedToday)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName ?? user.email)
                    .echoTextStyle(.title2)
                    .foregroundStyle(AppTheme.color.content.primary)
                if user.displayName != nil {

                    Text(user.email)
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, AppTheme.space.xs)
    }

    /// Sayılar tek satırda, ince çizgilerle ayrılır. Değeri olmayan alan (ör. ortalama mood) hiç gösterilmez.
    private func stats(_ user: AuthenticatedUser) -> some View {
        VStack(spacing: 0) {
            EchoHairline()
            HStack(spacing: 0) {
                statItem(value: "\(user.totalEntries)", label: "profile.totalEntries")
                statDivider
                statItem(value: "\(user.currentStreak)", label: "profile.currentStreak")
                statDivider
                statItem(value: "\(user.longestStreak)", label: "profile.longestStreak")
            }
            .padding(.vertical, AppTheme.space.sm)
            EchoHairline()
        }
    }

    private func statItem(value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .echoTextStyle(.title2)
                .monospacedDigit()
                .foregroundStyle(AppTheme.color.content.primary)
            Text(label)
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(AppTheme.color.border.subtle)
            .frame(width: 0.5, height: 32)
            .padding(.trailing, AppTheme.space.sm)
    }

    private var navigationSections: some View {
        VStack(spacing: AppTheme.space.md) {
            settingsGroup(title: "profile.echo") {
                row("profile.insights", icon: "sparkles") { router.push(.insights) }
                EchoDivider(insetLeading: 60)
                row("profile.goals", icon: "target") { router.push(.goals) }
                EchoDivider(insetLeading: 60)
                row("profile.capsules", icon: "hourglass") { router.push(.capsules) }
                EchoDivider(insetLeading: 60)
                row("profile.achievements", icon: "medal") { router.push(.achievements) }
                EchoDivider(insetLeading: 60)
                row("profile.coachSessions", icon: "bubble.left.and.text.bubble.right") { router.push(.coachSessions) }
            }
            settingsGroup(title: "profile.account") {
                row("profile.subscription", icon: "crown") { router.push(.subscription) }
                EchoDivider(insetLeading: 60)
                row("profile.settings", icon: "gearshape") { router.push(.settings) }
            }
        }
    }

    private func settingsGroup<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            EchoSectionHeader(title)
            EchoCard(style: .flat, padding: 0) { VStack(spacing: 0) { content() } }
        }
    }

    private func row(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        EchoListRow(title) { EchoListRowIcon(systemImage: icon) } trailing: { EchoDisclosureIndicator() }
            .echoRowButton(action: action)
    }
}
