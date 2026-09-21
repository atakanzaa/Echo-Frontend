import SwiftUI

/// Ana kabuk: sekme yığınları, merkez kayıt eylemi ve modal sunumları (implementation.md §5.0).
struct MainTabView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var router: AppRouter
    @State private var toasts = EchoToastCenter()
    @State private var sheetAfterRecording: AppSheet?
    @Environment(\.scenePhase) private var scenePhase

    @MainActor init(router: AppRouter? = nil) {
        _router = State(initialValue: router ?? AppRouter())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.color.bg.canvas.ignoresSafeArea()
            content
            EchoTabBar(selection: $router.selectedTab,
                       isRecording: router.sheet?.isRecording == true,
                       onRecordTap: { router.present(.recording()) },
                       onReselect: { router.popToRoot($0) })
        }
        .echoToasts(toasts)
        .fullScreenCover(isPresented: recordingPresented, onDismiss: presentDeferredSheet) {

            sheetContent(router.sheet ?? .recording())
        }
        .sheet(item: standardSheet) { sheet in

            sheetContent(sheet)
        }
        .task {
            if let userID = environment.session.state.user?.id {

                await environment.submissions.resumePending(for: userID)
            }
        }
        .task { await environment.usage.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await environment.usage.refresh() } }
        }
        // En dışta: sayfalar ve tam ekran sunumlar ortamı sunum modifier'ının bulunduğu yerden alır.
        // Bu iki satır sunumların içinde kalırsa açılan ekran yönlendiriciyi bulamaz ve uygulama çöker.
        .environment(router)
        .environment(toasts)
    }

    @ViewBuilder private var content: some View {
        switch router.selectedTab {
        case .today:
            tabStack(.today) {
                if let user = environment.session.state.user {
                    TodayView(user: user, environment: environment)
                } else {
                    PlaceholderScreen(title: "tabs.today")
                }
            }
        case .journal:
            tabStack(.journal) {
                JournalFeedView(journal: environment.journal,
                                insights: environment.insights,
                                timeZone: userTimeZone,
                                currentStreak: environment.session.state.user?.currentStreak ?? 0)
            }
        case .community:
            tabStack(.community) { CommunityFeedView(community: environment.community) }
        case .profile:
            tabStack(.profile) { ProfileView() }
        }
    }

    private func tabStack<Root: View>(_ tab: AppTab, @ViewBuilder root: () -> Root) -> some View {
        NavigationStack(path: router.path(for: tab)) {
            root()
                .echoTabBarInset()
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(destination).echoTabBarInset()
                }
        }
    }

    @ViewBuilder private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .journalEntry(let id):
            JournalEntryDetailView(id: id, journal: environment.journal,
                                   coach: environment.coach, goals: environment.goals,
                                   timeZone: userTimeZone)
        case .journalSearch:
            JournalSearchView(journal: environment.journal)
        case .insights:
            InsightsView(service: environment.insights, timeZone: userTimeZone,
                         currentStreak: environment.session.state.user?.currentStreak ?? 0)
        case .moodTracker(let periodDays):
            MoodTrackerView(periodDays: periodDays, service: environment.insights, timeZone: userTimeZone)
        case .communityPost(let id):
            CommunityPostDetailView(id: id, community: environment.community)
        case .achievements:
            AchievementsView(insights: environment.insights)
        case .goals:
            GoalsView(goals: environment.goals)
        case .createGoal:
            CreateGoalView(goals: environment.goals)
        case .capsules:
            CapsulesView(capsules: environment.capsules)
        case .createCapsule:
            CreateCapsuleView(capsules: environment.capsules,
                              presets: environment.remoteConfig.config?.capsulePresets ?? [])
        case .capsule(let id):
            CapsuleDetailView(id: id, capsules: environment.capsules)
        case .achievementDetail(let badgeKey):
            AchievementDetailView(key: badgeKey, insights: environment.insights)
        case .settings:
            SettingsView()
        case .notificationSettings:
            NotificationSettingsView(notifications: environment.notifications)
        case .blockedAuthors:
            BlockedAuthorsView(community: environment.community)
        case .editProfile:
            EditProfileView()
        case .privacyConsent:
            PrivacyConsentView(user: environment.user)
        case .notifications:
            NotificationsView(notifications: environment.notifications)
        case .coachSessions:
            CoachSessionsView(coach: environment.coach)
        case .subscription:
            SubscriptionView(subscription: environment.subscription)
        case .usage:
            UsageView()
        }
    }

    @ViewBuilder private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .recording(let prompt, _):
            RecordingView(prompt: prompt, onFinished: { entry in

                router.dismissSheet()
                router.push(.journalEntry(id: entry.id), on: .today)
            }, onSwitchToText: {
                sheetAfterRecording = .composer
                router.dismissSheet()
            })
        case .composer:
            NavigationStack {
                ComposerView { entry in

                    router.dismissSheet()
                    router.push(.journalEntry(id: entry.id), on: .today)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("common.cancel") { router.dismissSheet() }
                    }
                }
            }
        case .coachChat(let sessionID):
            NavigationStack {
                CoachChatView(sessionID: sessionID, coach: environment.coach)
            }
            .presentationDetents([.large])
            .presentationCornerRadius(AppTheme.radius.xl)
        case .composePost(let prefilledText):
            NavigationStack {
                ComposePostView(prefilledText: prefilledText,
                                community: environment.community,
                                user: environment.user) { post in
                    router.dismissSheet()
                    router.push(.communityPost(id: post.id), on: .community)
                }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(AppTheme.radius.xl)
        case .paywall:
            NavigationStack {
                PaywallView(subscription: environment.subscription) { router.dismissSheet() }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(AppTheme.radius.xl)
        }
    }

    private var recordingPresented: Binding<Bool> {
        Binding(
            get: { router.sheet?.isRecording == true },
            set: { isPresented in
                if !isPresented, router.sheet?.isRecording == true { router.dismissSheet() }
            })
    }

    private var standardSheet: Binding<AppSheet?> {
        Binding(
            get: { router.sheet?.isRecording == true ? nil : router.sheet },
            set: { router.sheet = $0 })
    }

    private func presentDeferredSheet() {
        guard let sheetAfterRecording else { return }
        self.sheetAfterRecording = nil
        router.present(sheetAfterRecording)
    }

    private var userTimeZone: TimeZone {
        environment.session.state.user?.resolvedTimeZone ?? .current
    }
}

/// Sonraki fazda gerçek ekranla değişecek geçici içerik. Sahte veri göstermez.
struct PlaceholderScreen: View {
    let title: LocalizedStringKey

    var body: some View {
        ScrollView {
            EchoEmptyState("placeholder.screenTitle", message: "placeholder.screenBody", systemImage: "square.dashed")
                .padding(.top, AppTheme.space.xxl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Ana kabuk") {
    MainTabView()
}
