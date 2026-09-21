import SwiftUI

struct JournalFeedView: View {
    private enum Segment: Hashable { case feed, calendar, insights }

    @Environment(AppRouter.self) private var router
    @Environment(\.locale) private var locale
    @State private var segment: Segment = .feed
    @State private var feedModel: JournalFeedViewModel
    @State private var calendarModel: JournalCalendarViewModel
    @State private var pendingDeleteID: String?

    private let timeZone: TimeZone
    private let insightsService: any InsightsServicing
    private let currentStreak: Int

    init(journal: any JournalServicing, insights: any InsightsServicing, timeZone: TimeZone, currentStreak: Int) {
        self.timeZone = timeZone
        self.insightsService = insights
        self.currentStreak = currentStreak
        _feedModel = State(initialValue: JournalFeedViewModel(journal: journal, timeZone: timeZone))
        _calendarModel = State(initialValue: JournalCalendarViewModel(journal: journal, insights: insights, timeZone: timeZone))
    }

    var body: some View {
        VStack(spacing: AppTheme.space.sm) {
            EchoSegmentedControl(selection: $segment, options: [
                .init(.feed, String(localized: "journal.segment.feed")),
                .init(.calendar, String(localized: "journal.segment.calendar")),
                .init(.insights, String(localized: "journal.segment.insights"))
            ])
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)

            switch segment {
            case .feed: feed
            case .calendar:
                JournalCalendarView(model: calendarModel, timeZone: timeZone) { id in
                    router.push(.journalEntry(id: id))
                }
            case .insights:
                InsightsView(service: insightsService, timeZone: timeZone, currentStreak: currentStreak)
            }
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("journal.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EchoIconButton("magnifyingglass", accessibilityTitle: "journal.search") {
                    router.push(.journalSearch)
                }
            }
        }
        .alert("journal.deleteTitle", isPresented: deleteAlertPresented) {
            Button("common.cancel", role: .cancel) { pendingDeleteID = nil }
            Button("common.delete", role: .destructive) {
                guard let id = pendingDeleteID else { return }
                Task {
                    _ = await feedModel.delete(id: id)
                    pendingDeleteID = nil
                }
            }
        } message: {
            Text("journal.deleteMessage")
        }
    }

    private var feed: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.space.sm, pinnedViews: [.sectionHeaders]) {
                if let error = feedModel.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) {
                            Task { await feedModel.loadNext() }
                        }
                    })
                }
                if feedModel.entries.isEmpty, !feedModel.isLoading {
                    EchoEmptyState("journal.empty", message: "journal.emptyMessage", systemImage: "book.closed") {
                        EchoButton("journal.record", variant: .secondary) { router.present(.recording) }
                    }
                } else {
                    ForEach(feedModel.groupedEntries) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                EchoEntryCard(
                                    model: JournalPresentation.cardModel(for: entry),
                                    onTap: { router.push(.journalEntry(id: entry.id)) },
                                    onDelete: { pendingDeleteID = entry.id }
                                )
                                .task {
                                    if entry.id == feedModel.entries.last?.id { await feedModel.loadNext() }
                                }
                            }
                        } header: {
                            Text(JournalPresentation.monthTitle(year: group.id.year, month: group.id.month, locale: locale))
                                .echoTextStyle(.caption2)
                                .textCase(.uppercase)
                                .foregroundStyle(AppTheme.color.content.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, AppTheme.space.xxs)
                                .background(AppTheme.color.bg.canvas)
                                .accessibilityAddTraits(.isHeader)
                        }
                    }
                    if feedModel.isLoading { ProgressView().frame(maxWidth: .infinity) }
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .refreshable { await feedModel.refresh() }
        // Detaydan geri dönüldüğünde sayaç ve liste sunucudan yeniden okunur.
        .task { await feedModel.refresh() }
    }

    private var deleteAlertPresented: Binding<Bool> {
        Binding(get: { pendingDeleteID != nil }, set: { if !$0 { pendingDeleteID = nil } })
    }
}
