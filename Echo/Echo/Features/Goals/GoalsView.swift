import SwiftUI

@Observable
@MainActor
private final class GoalsViewModel {
    enum Filter: Int, CaseIterable { case active, all }

    private(set) var goals: [Goal] = []
    private(set) var stats: GoalStats?
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: AppError?
    var filter: Filter = .active

    @ObservationIgnored private let service: any GoalServicing
    private var nextCursor: String?
    private var hasMore = false

    init(service: any GoalServicing) { self.service = service }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let page = filter == .active
                ? service.activeGoals(cursor: nil, size: 20)
                : service.allGoals(cursor: nil, size: 20)
            async let stats = service.stats()
            let (loadedPage, loadedStats) = try await (page, stats)
            goals = loadedPage.items
            nextCursor = loadedPage.nextCursor
            hasMore = loadedPage.hasMore
            self.stats = loadedStats
        } catch { self.error = AppError.from(error) }
    }

    func loadMoreIfNeeded(after goal: Goal) async {
        guard goal.id == goals.last?.id, hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await (filter == .active
                ? service.activeGoals(cursor: nextCursor, size: 20)
                : service.allGoals(cursor: nextCursor, size: 20))
            goals.append(contentsOf: page.items.filter { item in !goals.contains(where: { $0.id == item.id }) })
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch { self.error = AppError.from(error) }
    }

    func toggle(_ goal: Goal) async {
        do {
            let updated = goal.status == .completed
                ? try await service.markNotCompleted(id: goal.id)
                : try await service.complete(id: goal.id)
            replace(updated)
            stats = try? await service.stats()
            if filter == .active, !updated.status.isOpen { goals.removeAll { $0.id == updated.id } }
        } catch { self.error = AppError.from(error) }
    }

    func dismiss(_ goal: Goal) async {
        do {
            let updated = try await service.dismiss(id: goal.id)
            replace(updated)
            stats = try? await service.stats()
            if filter == .active { goals.removeAll { $0.id == goal.id } }
        } catch { self.error = AppError.from(error) }
    }

    func delete(_ goal: Goal) async {
        do {
            try await service.delete(id: goal.id)
            goals.removeAll { $0.id == goal.id }
            stats = try? await service.stats()
        } catch { self.error = AppError.from(error) }
    }

    private func replace(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index] = goal
    }
}

struct GoalsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @State private var model: GoalsViewModel
    @State private var pendingDeletion: Goal?

    init(goals: any GoalServicing) {
        _model = State(initialValue: GoalsViewModel(service: goals))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space.md) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error))
                }
                if let stats = model.stats { statsView(stats) }
                Picker("goals.filter", selection: $model.filter) {
                    Text("goals.active").tag(GoalsViewModel.Filter.active)
                    Text("goals.all").tag(GoalsViewModel.Filter.all)
                }
                .pickerStyle(.segmented)
                .onChange(of: model.filter) { _, _ in Task { await model.load() } }

                if model.goals.isEmpty, !model.isLoading {
                    EchoEmptyState("goals.empty", message: "goals.emptyMessage", systemImage: "target") {
                        EchoButton("goals.create", variant: .secondary) { router.push(.createGoal) }
                    }
                } else {
                    LazyVStack(spacing: AppTheme.space.sm) {
                        ForEach(model.goals) { goal in goalCard(goal).task { await model.loadMoreIfNeeded(after: goal) } }
                        if model.isLoadingMore { ProgressView() }
                    }
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("goals.title"))
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { router.push(.createGoal) } label: { Image(systemName: "plus") } } }
        .onAppear { Task { await model.load() } }
        .refreshable { await model.load() }
        .alert("goals.deleteTitle", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
            Button("common.delete", role: .destructive) {
                guard let goal = pendingDeletion else { return }
                pendingDeletion = nil
                Task { await model.delete(goal) }
            }
        } message: { Text("goals.deleteMessage") }
    }

    private func statsView(_ stats: GoalStats) -> some View {
        HStack(spacing: AppTheme.space.xs) {
            EchoStatTile(value: "\(stats.activeCount)", label: String(localized: "goals.activeCount"))
            EchoStatTile(value: "\(stats.completedCount)", label: String(localized: "goals.completedCount"))
            EchoStatTile(value: "\(stats.completedThisWeek)", label: String(localized: "goals.thisWeek"))
        }
    }

    private func goalCard(_ goal: Goal) -> some View {
        EchoCard(style: .flat) {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                        Text(goal.title).echoTextStyle(.headline)
                        if let timeframe = goal.timeframe, !timeframe.isEmpty {
                            Text(timeframe).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                        }
                    }
                    Spacer()
                    Text(environment.remoteConfig.vocabulary.label(goalStatus: goal.status))
                        .echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.accent)
                }
                HStack {
                    if goal.status.isOpen || goal.status == .completed {
                        Button { Task { await model.toggle(goal) } } label: {
                            Label(goal.status == .completed ? "goals.reopen" : "goals.complete",
                                  systemImage: goal.status == .completed ? "arrow.uturn.backward" : "checkmark.circle")
                        }
                    }
                    Spacer()
                    Menu {
                        if goal.status.isOpen { Button("goals.dismiss") { Task { await model.dismiss(goal) } } }
                        Button("common.delete", role: .destructive) { pendingDeletion = goal }
                    } label: { Image(systemName: "ellipsis") }
                }
                .echoTextStyle(.subhead)
            }
        }
    }
}

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var timeframe = ""
    @State private var isSaving = false
    @State private var error: AppError?
    let goals: any GoalServicing

    var body: some View {
        Form {
            Section {
                TextField("goals.titlePlaceholder", text: $title)
                TextField("goals.timeframePlaceholder", text: $timeframe)
            }
            if let error { Text(JournalPresentation.errorMessage(error)).foregroundStyle(AppTheme.color.feedback.danger) }
            EchoButton("goals.save", fullWidth: true, isLoading: isSaving) { Task { await save() } }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("goals.createTitle"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true; error = nil
        defer { isSaving = false }
        do {
            _ = try await goals.create(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                       timeframe: timeframe.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                                       idempotencyKey: UUID().uuidString)
            dismiss()
        } catch { self.error = AppError.from(error) }
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
