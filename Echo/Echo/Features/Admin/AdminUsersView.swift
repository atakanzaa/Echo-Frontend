import SwiftUI
import EchoAdminContract

/// Kullanıcı arama: e-posta, ad ya da kimlik. Arama sunucuda yapılır.
struct AdminUsersView: View {
    @Environment(AdminStore.self) private var store
    @State private var query = ""
    @State private var results: [AdminAPI.AdminUserSummaryResponse] = []
    @State private var searched = false
    @State private var error: AppError?

    var body: some View {
        List {
            if let error {

                EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.unexpected"))
                    .listRowBackground(Color.clear)
            }
            if searched, results.isEmpty, error == nil {

                Text("admin.users.none").foregroundStyle(AppTheme.color.content.secondary)
            }
            ForEach(results) { user in

                NavigationLink(value: AdminUserRoute(id: user.id)) { AdminUserRow(user: user) }
                    .listRowBackground(AppTheme.color.bg.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("admin.tab.users"))
        .searchable(text: $query, prompt: Text("admin.users.searchPrompt"))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) { Task { await search() } }
        .navigationDestination(for: AdminUserRoute.self) { AdminUserDetailView(id: $0.id) }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else { return }
        do {
            results = try await store.service.searchUsers(text)
            error = nil
        } catch {
            self.error = AppError.displayable(error)
        }
        searched = true
    }
}

struct AdminUserRow: View {
    let user: AdminAPI.AdminUserSummaryResponse

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
            HStack(spacing: AppTheme.space.xxs) {
                Text(verbatim: user.email).echoTextStyle(.subhead).lineLimit(1)
                if let until = user.bannedUntil, until > .now { EchoChip(String(localized: "admin.users.banned"), systemImage: "hand.raised") }
                if user.role == "admin" { EchoChip("admin") }
            }
            Text(verbatim: [user.displayName, user.tier, AdminFormat.ago(user.createdAt)].compactMap { $0 }.joined(separator: " · "))
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.secondary)
        }
    }
}

/// Bir hesabın tüm resmi ve üzerindeki işlemler. Yönetici hesaplarında işlemleri sunucu reddeder.
struct AdminUserDetailView: View {
    let id: String
    @Environment(AdminStore.self) private var store
    @Environment(EchoToastCenter.self) private var toasts
    @State private var profile: AdminAPI.AdminUserProfileResponse?
    @State private var error: AppError?
    @State private var pending: AdminPendingAction?
    @State private var newBlock: AdminBlockDraft?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                if let error {

                    EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.unexpected"))
                }
                if let profile {

                    summary(profile)
                    actions(profile)
                    addresses(profile)
                } else if error == nil {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.vertical, AppTheme.space.md)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text(verbatim: profile?.user.email ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .echoRefreshable { await load() }
        .sheet(item: $pending) { action in

            AdminConfirmSheet(action: action) { toasts.show(.init($0, systemImage: "checkmark")) }
        }
        .sheet(item: $newBlock) { draft in

            AdminNewBlockSheet(draft: draft) { toasts.show(.init($0, systemImage: "checkmark")) }
        }
    }

    private func load() async {
        do {
            profile = try await store.service.user(id: id)
            error = nil
        } catch {
            self.error = AppError.displayable(error)
        }
    }

    private func summary(_ profile: AdminAPI.AdminUserProfileResponse) -> some View {
        let user = profile.user
        return EchoCard {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                if let until = user.bannedUntil, until > .now {

                    EchoBanner(kind: .danger, title: String(format: String(localized: "admin.user.bannedUntil"), AdminFormat.moment(until)),
                               message: profile.banReason)
                }
                row("admin.user.name", user.displayName ?? "—")
                row("admin.user.plan", user.tier)
                row("admin.user.role", user.role)
                row("admin.user.joined", AdminFormat.moment(user.createdAt))
                row("admin.user.lastSession", profile.lastSessionAt.map(AdminFormat.ago) ?? "—")
                row("admin.user.entries", AdminFormat.count(profile.entryCount))
                row("admin.user.posts", AdminFormat.count(profile.postCount))
                row("admin.user.reports", AdminFormat.count(profile.reportsAgainst))
                row("admin.user.aiToday", "%\(profile.aiUsage.usedPercent)")
            }
        }
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title).echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.secondary)
            Spacer()
            Text(verbatim: value).echoTextStyle(.subhead).monospacedDigit().lineLimit(1)
        }
    }

    private func actions(_ profile: AdminAPI.AdminUserProfileResponse) -> some View {
        let service = store.service
        let userID = profile.user.id
        let banned = profile.user.bannedUntil.map { $0 > .now } ?? false
        let apply: @MainActor (AdminAPI.AdminUserProfileResponse) -> Void = { self.profile = $0 }
        return VStack(spacing: AppTheme.space.xs) {
            if banned {

                EchoButton("admin.user.unban", variant: .secondary, fullWidth: true) {
                    pending = AdminPendingAction(title: String(localized: "admin.user.unban"), destructive: false) { input in
                        apply(try await service.unban(userID: userID, reason: input.reason))
                    }
                }
            } else {
                EchoButton("admin.user.ban", variant: .destructive, leadingIcon: "hand.raised", fullWidth: true) {
                    pending = AdminPendingAction(title: String(localized: "admin.user.ban"),
                                                 message: String(localized: "admin.user.banMessage"), asksDuration: true) { input in
                        apply(try await service.ban(userID: userID, duration: input.duration, reason: input.reason))
                    }
                }
            }
            HStack(spacing: AppTheme.space.xs) {
                EchoButton("admin.user.signOut", variant: .tertiary, fullWidth: true) {
                    pending = AdminPendingAction(title: String(localized: "admin.user.signOut"),
                                                 message: String(localized: "admin.user.signOutMessage")) { input in
                        apply(try await service.signOut(userID: userID, reason: input.reason))
                    }
                }
                EchoButton("admin.user.resetAi", variant: .tertiary, fullWidth: true) {
                    pending = AdminPendingAction(title: String(localized: "admin.user.resetAi"), destructive: false) { input in
                        apply(try await service.resetAllowance(userID: userID, reason: input.reason))
                    }
                }
            }
            EchoButton("admin.user.blockEmail", variant: .ghost, size: .sm) {
                newBlock = AdminBlockDraft(kind: "email", value: profile.user.email)
            }
        }
    }

    private func addresses(_ profile: AdminAPI.AdminUserProfileResponse) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.user.addresses")
            if profile.addresses.isEmpty {

                Text("admin.user.noAddresses").echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
            }
            ForEach(profile.addresses, id: \.ip) { address in

                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
                        Text(verbatim: address.ip).echoTextStyle(.subhead).monospaced()
                        Text(verbatim: "\(address.hits)× · \(AdminFormat.ago(address.lastSeen))")
                            .echoTextStyle(.caption)
                            .foregroundStyle(AppTheme.color.content.secondary)
                    }
                    Spacer()
                    if address.blocked {

                        EchoChip(String(localized: "admin.blocks.blocked"), systemImage: "hand.raised")
                    } else {
                        Button("admin.blocks.block") { newBlock = AdminBlockDraft(kind: "ip", value: address.ip) }
                            .echoTextStyle(.subhead)
                    }
                }
                .padding(.vertical, AppTheme.space.xxxs)
            }
        }
    }
}
