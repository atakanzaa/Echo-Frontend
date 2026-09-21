import SwiftUI

struct CoachChatView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: CoachChatViewModel
    @State private var confirmation: Confirmation?
    @State private var sendTask: Task<Void, Never>?

    private enum Confirmation: String, Identifiable {
        case end, delete
        var id: String { rawValue }
    }

    init(sessionID: String?, coach: any CoachServicing) {
        _model = State(initialValue: CoachChatViewModel(sessionID: sessionID, coach: coach))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.space.xs) {
                    if model.hasMore {
                        EchoButton("coach.loadOlder", variant: .ghost, size: .sm) { Task { await model.loadOlder() } }
                    }
                    if let error = model.error {
                        EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                            if model.canRetry {
                                EchoButton("common.retry", variant: .ghost, size: .sm) {
                                    if model.sessionID == nil {
                                        Task { await model.start() }
                                    } else {
                                        sendMessage()
                                    }
                                }
                            }
                        })
                    }
                    if model.items.isEmpty, !model.isLoading {
                        EchoEmptyState("coach.empty", message: "coach.emptyMessage", systemImage: "sparkles")
                    }
                    ForEach(model.items) { item in
                        EchoChatBubble(role: item.role, text: item.text,
                                       onCopy: { UIPasteboard.general.string = item.text })
                            .id(item.id)
                    }
                    if model.isThinking {
                        HStack {
                            EchoTypingIndicator()
                            Spacer()
                        }
                        .id("thinking")
                    }
                    if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
                }
                .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
                .padding(.vertical, AppTheme.space.sm)
            }
            .background(AppTheme.color.bg.canvas)
            .onChange(of: model.items.count) { _, _ in
                if let id = model.items.last?.id { withAnimation(AppTheme.motion.smooth) { proxy.scrollTo(id, anchor: .bottom) } }
            }
            .onChange(of: model.isThinking) { _, thinking in
                if thinking { withAnimation(AppTheme.motion.smooth) { proxy.scrollTo("thinking", anchor: .bottom) } }
            }
        }
        .safeAreaInset(edge: .bottom) { composer }
        .navigationTitle(Text("coach.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EchoIconButton("xmark", accessibilityTitle: "common.close") { router.dismissSheet() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("coach.end", systemImage: "stop.circle") { confirmation = .end }
                    Button("coach.delete", systemImage: "trash", role: .destructive) { confirmation = .delete }
                } label: { Image(systemName: "ellipsis") }
                    .disabled(model.sessionID == nil)
            }
        }
        .task { await model.start() }
        .onDisappear { sendTask?.cancel() }
        .alert(item: $confirmation) { choice in
            switch choice {
            case .end:
                Alert(title: Text("coach.endTitle"), message: Text("coach.endMessage"),
                      primaryButton: .cancel(), secondaryButton: .default(Text("coach.end")) {
                          Task { if await model.endSession() { router.dismissSheet() } }
                      })
            case .delete:
                Alert(title: Text("coach.deleteTitle"), message: Text("coach.deleteMessage"),
                      primaryButton: .cancel(), secondaryButton: .destructive(Text("common.delete")) {
                          Task { if await model.deleteSession() { router.dismissSheet() } }
                      })
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: AppTheme.space.xxs) {
            TextField("coach.placeholder", text: $model.draft, axis: .vertical)
                .lineLimit(1...5)
                .echoTextStyle(.body)
                .padding(.horizontal, AppTheme.space.xs)
                .padding(.vertical, AppTheme.space.xxs)
                .background(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous)
                    .fill(AppTheme.color.bg.surfaceSunken))
                .disabled(model.isSending || model.isThinking)
                .submitLabel(.send)
                .onSubmit { if model.canSend { sendMessage() } }
            EchoIconButton("arrow.up", accessibilityTitle: "coach.send", variant: .filled) {
                sendMessage()
            }
            .disabled(!model.canSend)
        }
        .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
        .padding(.vertical, AppTheme.space.xxs)
        .background(.ultraThinMaterial)
    }

    private func sendMessage() {
        sendTask?.cancel()
        sendTask = Task { await model.send() }
    }
}
