import SwiftUI

struct JournalSearchView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: JournalSearchViewModel

    init(journal: any JournalServicing) {
        _model = State(initialValue: JournalSearchViewModel(journal: journal))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.space.sm) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.loadNext() } }
                    })
                }
                content
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("journal.search"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("journal.searchPrompt"))
        .task(id: model.query) { await model.queryChanged() }
    }

    @ViewBuilder private var content: some View {
        if model.normalizedQuery.isEmpty {
            EchoEmptyState("journal.searchEmpty", message: "journal.searchEmptyMessage", systemImage: "magnifyingglass")
        } else if model.isTooShort {
            EchoBanner(kind: .info, title: String(localized: "journal.searchTooShort"))
        } else if model.isTooLong {
            EchoBanner(kind: .warning, title: String(localized: "journal.searchTooLong"))
        } else if model.results.isEmpty, !model.isLoading {
            EchoEmptyState("journal.noResults", message: "journal.noResultsMessage", systemImage: "text.magnifyingglass")
        } else {
            ForEach(model.results) { entry in
                searchResult(entry)
                    .task { if entry.id == model.results.last?.id { await model.loadNext() } }
            }
            if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
        }
    }

    private func searchResult(_ entry: JournalEntry) -> some View {
        EchoInteractiveCard(action: { router.push(.journalEntry(id: entry.id)) }) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                HStack(spacing: AppTheme.space.xxs) {
                    if let category = entry.analysis?.moodCategory {
                        EchoMoodGlyph(level: category.displayLevel, size: 14)
                    }
                    Text(entry.recordedAt, format: .dateTime.day().month(.wide).year())
                        .echoTextStyle(.caption)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                    Spacer(minLength: 0)
                }
                if let transcript = entry.transcript, !transcript.isEmpty {
                    highlighted(transcript, query: model.normalizedQuery)
                        .echoTextStyle(.entry)
                        .foregroundStyle(AppTheme.color.content.secondary)
                        .lineLimit(4)
                }
                if let status = JournalPresentation.statusText(for: entry) {
                    Text(status).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
        }
    }

    @ViewBuilder private func highlighted(_ source: String, query: String) -> some View {
        if let range = source.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
            Text(String(source[..<range.lowerBound]))
            + Text(String(source[range])).bold().foregroundColor(AppTheme.color.content.accent)
            + Text(String(source[range.upperBound...]))
        } else {
            Text(source)
        }
    }
}
