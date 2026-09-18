import SwiftUI

/// Ana kabuk: sekme yığınları, merkez kayıt eylemi ve modal sunumları (implementation.md §5.0).
struct MainTabView: View {
    @State private var router = AppRouter()
    @State private var toasts = EchoToastCenter()

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.color.bg.canvas.ignoresSafeArea()
            content
                // Sekme çubuğu içeriğin üstünde durur; alt boşluk içerik tarafından bırakılır.
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: AppTheme.layout.tabBarHeight) }
            EchoTabBar(selection: $router.selectedTab,
                       isRecording: router.sheet == .recording,
                       onRecordTap: { router.present(.recording) },
                       onReselect: { router.popToRoot($0) })
        }
        .environment(router)
        .environment(toasts)
        .echoToasts(toasts)
        .sheet(item: $router.sheet) { sheet in

            sheetContent(sheet)
        }
    }

    @ViewBuilder private var content: some View {
        switch router.selectedTab {
        case .today: tabStack(.today) { PlaceholderScreen(title: "tabs.today") }
        case .journal: tabStack(.journal) { PlaceholderScreen(title: "tabs.journal") }
        case .community: tabStack(.community) { PlaceholderScreen(title: "tabs.community") }
        case .profile: tabStack(.profile) { PlaceholderScreen(title: "tabs.profile") }
        }
    }

    private func tabStack<Root: View>(_ tab: AppTab, @ViewBuilder root: () -> Root) -> some View {
        NavigationStack(path: router.path(for: tab)) {
            root()
                .navigationDestination(for: AppDestination.self) { destination in

                    PlaceholderScreen(title: LocalizedStringKey(String(describing: destination)))
                }
        }
    }

    @ViewBuilder private func sheetContent(_ sheet: AppSheet) -> some View {
        NavigationStack {
            PlaceholderScreen(title: LocalizedStringKey(sheet.id))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.close") { router.dismissSheet() }
                    }
                }
        }
        .presentationDetents(sheet == .recording ? [.large] : [.medium, .large])
        .presentationCornerRadius(AppTheme.radius.xl)
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
