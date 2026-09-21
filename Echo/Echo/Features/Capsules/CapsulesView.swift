import SwiftUI

@Observable
@MainActor
private final class CapsulesViewModel {
    private(set) var capsules: [TimeCapsule] = []
    private(set) var summary: CapsuleSummary?
    private(set) var isLoading = false
    private(set) var error: AppError?
    @ObservationIgnored private let service: any CapsuleServicing

    init(service: any CapsuleServicing) { self.service = service }

    func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            async let page = service.list(cursor: nil, size: 50)
            async let summary = service.summary()
            let (loadedPage, loadedSummary) = try await (page, summary)
            capsules = loadedPage.items
            self.summary = loadedSummary
        } catch { self.error = AppError.from(error) }
    }
}

struct CapsulesView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: CapsulesViewModel

    init(capsules: any CapsuleServicing) {
        _model = State(initialValue: CapsulesViewModel(service: capsules))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space.md) {
                if let error = model.error { EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error)) }
                if let summary = model.summary { summaryView(summary) }
                if model.capsules.isEmpty, !model.isLoading {
                    EchoEmptyState("capsules.empty", message: "capsules.emptyMessage", systemImage: "hourglass") {
                        EchoButton("capsules.create", variant: .secondary) { router.push(.createCapsule) }
                    }
                } else {
                    LazyVStack(spacing: AppTheme.space.sm) {
                        ForEach(model.capsules) { capsule in
                            EchoInteractiveCard(style: .flat, action: { router.push(.capsule(id: capsule.id)) }) {
                                capsuleRow(capsule)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("capsules.title"))
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { router.push(.createCapsule) } label: { Image(systemName: "plus") } } }
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private func summaryView(_ summary: CapsuleSummary) -> some View {
        HStack(spacing: AppTheme.space.xs) {
            EchoStatTile(value: "\(summary.sealedCount)", label: String(localized: "capsules.sealed"))
            EchoStatTile(value: "\(summary.openableCount)", label: String(localized: "capsules.openable"))
            EchoStatTile(value: "\(summary.openedCount)", label: String(localized: "capsules.opened"))
        }
    }

    private func capsuleRow(_ capsule: TimeCapsule) -> some View {
        HStack(spacing: AppTheme.space.sm) {
            Image(systemName: capsule.status == .opened ? "envelope.open" : "lock.fill")
                .font(.system(size: AppTheme.icon.lg))
                .foregroundStyle(capsule.canOpen ? AppTheme.color.content.accent : AppTheme.color.content.tertiary)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                Text(capsule.title ?? String(localized: "capsules.untitled")).echoTextStyle(.headline)
                Text(capsule.status == .opened
                     ? String(localized: "capsules.openedStatus")
                     : capsule.unlockAt.formatted(date: .abbreviated, time: .shortened))
                    .echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
            }
            Spacer()
            if capsule.canOpen { Text("capsules.ready").echoTextStyle(.caption2).foregroundStyle(AppTheme.color.content.accent) }
            EchoDisclosureIndicator()
        }
    }
}

struct CreateCapsuleView: View {
    @Environment(\.dismiss) private var dismiss
    let capsules: any CapsuleServicing
    let presets: [RemoteAppConfig.CapsulePreset]
    @State private var title = ""
    @State private var text = ""
    @State private var selectedPresetKey: String?
    @State private var isSaving = false
    @State private var error: AppError?

    private var selectedPreset: RemoteAppConfig.CapsulePreset? {
        presets.first { $0.key == selectedPresetKey } ?? presets.first
    }

    var body: some View {
        Form {
            Section("capsules.content") {
                TextField("capsules.titlePlaceholder", text: $title)
                TextEditor(text: $text).frame(minHeight: 160)
            }
            Section("capsules.unlock") {
                if presets.isEmpty {
                    Text("capsules.noPresets").foregroundStyle(AppTheme.color.content.secondary)
                } else {
                    Picker("capsules.duration", selection: $selectedPresetKey) {
                        ForEach(presets) { preset in Text(preset.label).tag(Optional(preset.key)) }
                    }
                }
            }
            if let error { Text(JournalPresentation.errorMessage(error)).foregroundStyle(AppTheme.color.feedback.danger) }
            EchoButton("capsules.seal", fullWidth: true, isLoading: isSaving) { Task { await save() } }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPreset == nil)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("capsules.createTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedPresetKey = selectedPresetKey ?? presets.first?.key }
    }

    private func save() async {
        guard let preset = selectedPreset, !isSaving else { return }
        isSaving = true; error = nil
        defer { isSaving = false }
        do {
            let unlockAt = Calendar.current.date(byAdding: .day, value: preset.days, to: .now) ?? .now
            _ = try await capsules.create(title: title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                                          text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                                          unlockAt: unlockAt,
                                          idempotencyKey: UUID().uuidString)
            dismiss()
        } catch { self.error = AppError.from(error) }
    }
}

@Observable
@MainActor
private final class CapsuleDetailViewModel {
    private(set) var capsule: TimeCapsule?
    private(set) var isLoading = false
    private(set) var error: AppError?
    let id: String
    @ObservationIgnored private let service: any CapsuleServicing

    init(id: String, service: any CapsuleServicing) { self.id = id; self.service = service }
    func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do { capsule = try await service.capsule(id: id) }
        catch { self.error = AppError.from(error) }
    }
    func open() async {
        do { capsule = try await service.open(id: id) }
        catch { self.error = AppError.from(error) }
    }
    func delete() async throws { try await service.delete(id: id) }
}

struct CapsuleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: CapsuleDetailViewModel
    @State private var showsDelete = false

    init(id: String, capsules: any CapsuleServicing) {
        _model = State(initialValue: CapsuleDetailViewModel(id: id, service: capsules))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space.lg) {
                if let error = model.error { EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error)) }
                if let capsule = model.capsule {
                    EchoRippleMark(systemImage: capsule.status == .opened ? "envelope.open" : "lock.fill")
                    Text(capsule.title ?? String(localized: "capsules.untitled")).echoTextStyle(.title1).multilineTextAlignment(.center)
                    if capsule.status == .opened, let content = capsule.contentText {
                        EchoCard(style: .raised) { Text(content).echoTextStyle(.body) }
                    } else {
                        Text(capsule.unlockAt, format: .dateTime.day().month(.wide).year().hour().minute())
                            .echoTextStyle(.body).foregroundStyle(AppTheme.color.content.secondary)
                        if capsule.canOpen { EchoButton("capsules.open") { Task { await model.open() } } }
                    }
                    EchoButton("common.delete", variant: .ghost) { showsDelete = true }
                } else if model.isLoading { ProgressView() }
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("capsules.detailTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .alert("capsules.deleteTitle", isPresented: $showsDelete) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) { Task { try? await model.delete(); dismiss() } }
        } message: { Text("capsules.deleteMessage") }
    }
}
