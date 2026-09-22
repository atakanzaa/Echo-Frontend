import SwiftUI
import EchoAdminContract

/// Aktif engeller. Otomatik engeller 24 saatliktir; buradan kalıcı yapılır ya da kaldırılır.
struct AdminBlocksView: View {
    @Environment(AdminStore.self) private var store
    @Environment(EchoToastCenter.self) private var toasts
    @State private var autoOnly = false
    @State private var blocks: [AdminAPI.AccessBlockResponse] = []
    @State private var loaded = false
    @State private var error: AppError?
    @State private var pending: AdminPendingAction?
    @State private var newBlock: AdminBlockDraft?

    var body: some View {
        List {
            EchoSegmentedControl(selection: $autoOnly, options: [.init(false, String(localized: "common.all")),
                                                                 .init(true, String(localized: "admin.blocks.auto"))])
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            if let error {

                EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.unexpected"))
                    .listRowBackground(Color.clear)
            }
            if loaded, blocks.isEmpty {

                Text("admin.blocks.none").foregroundStyle(AppTheme.color.content.secondary)
            }
            ForEach(blocks) { block in

                AdminBlockRow(block: block)
                    .listRowBackground(AppTheme.color.bg.surface)
                    .swipeActions(edge: .trailing) {
                        Button("admin.blocks.lift", role: .destructive) { pending = lift(block) }
                        if block.expiresAt != nil {

                            Button("admin.blocks.keep") { pending = keep(block) }.tint(AppTheme.color.accent.primary)
                        }
                    }
                    .contextMenu {
                        Button("admin.blocks.lift", systemImage: "hand.raised.slash") { pending = lift(block) }
                        if block.expiresAt != nil {

                            Button("admin.blocks.keep", systemImage: "infinity") { pending = keep(block) }
                        }
                    }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("admin.tab.blocks"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { newBlock = AdminBlockDraft() } label: { Image(systemName: "plus") }
                    .accessibilityLabel(Text("admin.block.create"))
            }
        }
        .task(id: autoOnly) { await load() }
        .echoRefreshable { await load() }
        .sheet(item: $pending) { action in

            AdminConfirmSheet(action: action) { done($0) }
        }
        .sheet(item: $newBlock) { draft in

            AdminNewBlockSheet(draft: draft) { done($0) }
        }
    }

    private func done(_ title: String) {
        toasts.show(.init(title, systemImage: "checkmark"))
        Task { await load() }
    }

    private func load() async {
        do {
            blocks = try await store.service.blocks(autoOnly: autoOnly)
            error = nil
        } catch {
            if let shown = AppError.displayable(error) { self.error = shown }
        }
        loaded = true
    }

    private func lift(_ block: AdminAPI.AccessBlockResponse) -> AdminPendingAction {
        let service = store.service
        return AdminPendingAction(title: String(localized: "admin.blocks.lift"), message: block.value, destructive: false) { input in
            try await service.liftBlock(id: block.id, reason: input.reason)
        }
    }

    private func keep(_ block: AdminAPI.AccessBlockResponse) -> AdminPendingAction {
        let service = store.service
        return AdminPendingAction(title: String(localized: "admin.blocks.keep"), message: block.value) { input in
            try await service.confirmBlock(id: block.id, reason: input.reason)
        }
    }
}

struct AdminBlockRow: View {
    let block: AdminAPI.AccessBlockResponse

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
            HStack(spacing: AppTheme.space.xxs) {
                EchoChip(AdminFormat.blockKindTitle(block.kind))
                if block.source == "auto" { EchoChip(String(localized: "admin.blocks.auto"), systemImage: "bolt") }
                Spacer()
                Text(verbatim: block.expiresAt.map(AdminFormat.moment) ?? String(localized: "admin.duration.permanent"))
                    .echoTextStyle(.caption)
                    .foregroundStyle(AppTheme.color.content.tertiary)
            }
            Text(verbatim: block.value).echoTextStyle(.bodyEmphasis).monospaced().lineLimit(1)
            Text(verbatim: [block.reason, block.createdBy].compactMap { $0 }.joined(separator: " · "))
                .echoTextStyle(.footnote)
                .foregroundStyle(AppTheme.color.content.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, AppTheme.space.xxxs)
    }
}
