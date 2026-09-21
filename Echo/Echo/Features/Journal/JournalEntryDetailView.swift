import SwiftUI

struct JournalEntryDetailView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var model: JournalEntryDetailViewModel
    @State private var showsDeleteConfirmation = false

    private let timeZone: TimeZone

    init(id: String, journal: any JournalServicing, coach: any CoachServicing,
         goals: any GoalServicing, timeZone: TimeZone) {
        self.timeZone = timeZone
        _model = State(initialValue: JournalEntryDetailViewModel(entryID: id, journal: journal, coach: coach, goals: goals))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await model.start() } }
                    })
                }
                if let entry = model.entry {
                    entryContent(entry)
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 260)
                }
            }
            .frame(maxWidth: AppTheme.layout.readableEntryWidth)
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.color.bg.canvas)
        .environment(\.timeZone, timeZone)
        .navigationTitle(Text("journal.detailTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailMenu }
        .task { await model.start() }
        .alert("journal.deleteTitle", isPresented: $showsDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                Task { if await model.delete() { dismiss() } }
            }
        } message: {
            Text("journal.deleteMessage")
        }
    }

    @ViewBuilder private func entryContent(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            Text(entry.recordedAt, format: .dateTime.day().month(.wide).year())
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
            Text(entry.recordedAt, format: .dateTime.hour().minute())
                .echoTextStyle(.title1)
                .foregroundStyle(AppTheme.color.content.primary)
        }

        statusSection(entry)

        if let transcript = entry.transcript, !transcript.isEmpty {
            Text(transcript)
                .echoTextStyle(.entry)
                .foregroundStyle(AppTheme.color.content.primary)
                .textSelection(.enabled)
        }

        if let analysis = entry.analysis {
            analysisSection(analysis)
            goalSuggestions
            actions(entry)
        }
    }

    @ViewBuilder private func statusSection(_ entry: JournalEntry) -> some View {
        switch entry.status {
        case .failed:
            // `errorCode` makine sözlüğüdür; kullanıcıya ham değer gösterilmez.
            EchoBanner(kind: .danger, title: String(localized: "journal.status.failed"))
        case .cancelled:
            EchoBanner(kind: .warning, title: String(localized: "journal.status.cancelled"))
        case .queued, .processing, .retryScheduled, .unknown:
            EchoBanner(kind: .info, title: String(localized: "journal.status.processing"),
                       message: processingStage)
        case .succeeded:
            if entry.analysis == nil {
                EchoBanner(kind: .info, title: String(localized: "journal.analysisUnavailable"))
            }
        }
    }

    private func analysisSection(_ analysis: JournalAnalysis) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.md) {
            EchoReflectionBlock(text: [analysis.summary, analysis.reflectiveQuestion]
                .filter { !$0.isEmpty }.joined(separator: "\n\n"))

            HStack(spacing: AppTheme.space.xs) {
                EchoChip(analysis.moodLabel, style: .mood(analysis.moodCategory.displayLevel))
                if let energy = energyLabel(analysis.energyLevel) {
                    EchoChip(energy, systemImage: "bolt")
                }
            }

            if !analysis.topics.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                    Text("journal.topics").echoTextStyle(.caption2).textCase(.uppercase)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                    FlowLayout(spacing: AppTheme.space.xxs) {
                        ForEach(analysis.topics, id: \.self) { EchoChip($0) }
                    }
                }
            }

            if !analysis.keyEmotions.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                    Text("journal.emotions").echoTextStyle(.caption2).textCase(.uppercase)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                    Text(analysis.keyEmotions.joined(separator: " · "))
                        .echoTextStyle(.body)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
            }
        }
    }

    private func actions(_ entry: JournalEntry) -> some View {
        VStack(spacing: AppTheme.space.xs) {
            EchoButton("journal.coach", variant: .secondary, leadingIcon: "sparkles", fullWidth: true,
                       isLoading: model.isStartingCoach) {
                Task {
                    if let sessionID = await model.createCoachSession() {
                        router.present(.coachChat(sessionId: sessionID))
                    }
                }
            }
            EchoButton("journal.communityShare", variant: .tertiary, leadingIcon: "person.2", fullWidth: true) {
                router.present(.composePost(prefilledText: shareText(entry)))
            }
        }
    }

    @ViewBuilder private var goalSuggestions: some View {
        if !model.goalSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                EchoSectionHeader("journal.goalSuggestions")
                ForEach(model.goalSuggestions) { suggestion in
                    EchoCard(style: .flat) {
                        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                            if let title = suggestion.title, !title.isEmpty {
                                Text(title).echoTextStyle(.headline).foregroundStyle(AppTheme.color.content.primary)
                            }
                            Text(suggestion.message)
                                .echoTextStyle(.body)
                                .foregroundStyle(AppTheme.color.content.secondary)
                            HStack(spacing: AppTheme.space.xs) {
                                EchoButton(verbatimTitle: suggestion.primaryActionLabel, variant: .secondary,
                                           size: .sm, isLoading: model.workingSuggestionID == suggestion.id) {
                                    Task { await model.acceptSuggestion(id: suggestion.id) }
                                }
                                .disabled(model.workingSuggestionID != nil)
                                EchoButton(verbatimTitle: suggestion.secondaryActionLabel, variant: .ghost, size: .sm) {
                                    Task { await model.rejectSuggestion(id: suggestion.id) }
                                }
                                .disabled(model.workingSuggestionID != nil)
                            }
                        }
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder private var detailMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let entry = model.entry, !shareText(entry).isEmpty {
                    ShareLink(item: shareText(entry)) {
                        Label("common.share", systemImage: "square.and.arrow.up")
                    }
                }
                Button("common.delete", systemImage: "trash", role: .destructive) {
                    showsDeleteConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel(Text("journal.moreActions"))
        }
    }

    private var processingStage: String? {
        guard let stage = model.progress?.stage else { return nil }
        switch stage {
        case .transcription: return String(localized: "journal.stage.transcription")
        case .analysis: return String(localized: "journal.stage.analysis")
        case .response, .sessionCreated, .synthesis, .unknown: return nil
        }
    }

    private func energyLabel(_ energy: EchoEnergyLevel) -> String? {
        switch energy {
        case .low: String(localized: "journal.energy.low")
        case .medium: String(localized: "journal.energy.medium")
        case .high: String(localized: "journal.energy.high")
        case .unknown: nil
        }
    }

    private func shareText(_ entry: JournalEntry) -> String {
        [entry.analysis?.summary, entry.transcript]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
