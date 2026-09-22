import SwiftUI
import EchoAdminContract

/// Yönetici hesabının tek ekranı. Açılışta ve uygulamaya her dönüşte Face ID ister; günlük özellikleri yoktur.
struct AdminRootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: AdminStore
    @State private var tab: AdminTab = .status
    @State private var logKind: AdminLogKind = .alerts
    @State private var usersPath = NavigationPath()
    @State private var unlocked: Bool
    @State private var openedAlert: AdminAPI.AdminAlertResponse?
    @State private var toasts = EchoToastCenter()

    init(service: any AdminServicing, requiresUnlock: Bool = true) {
        _store = State(initialValue: AdminStore(service: service))
        _unlocked = State(initialValue: !requiresUnlock)
    }

    var body: some View {
        Group {
            if unlocked {

                tabs
            } else {
                gate
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Face ID penceresi uygulamayı yalnız "inactive" yapar; kilit arka plana geçişte kurulur.
            if phase == .background { unlocked = false }
        }
        .environment(store)
        .environment(toasts)
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            NavigationStack { AdminStatusView(onOpenAlert: { openedAlert = $0 }) }
                .tabItem { Label("admin.tab.status", systemImage: "gauge.with.dots.needle.33percent") }
                .tag(AdminTab.status)
            NavigationStack(path: $usersPath) { AdminUsersView() }
                .tabItem { Label("admin.tab.users", systemImage: "person.2") }
                .tag(AdminTab.users)
            NavigationStack { AdminBlocksView() }
                .tabItem { Label("admin.tab.blocks", systemImage: "hand.raised") }
                .tag(AdminTab.blocks)
            NavigationStack { AdminTrafficView() }
                .tabItem { Label("admin.tab.traffic", systemImage: "chart.bar.xaxis") }
                .tag(AdminTab.traffic)
            NavigationStack { AdminLogsView(kind: $logKind, onOpenAlert: { openedAlert = $0 }) }
                .tabItem { Label("admin.tab.logs", systemImage: "list.bullet.rectangle") }
                .tag(AdminTab.logs)
        }
        .tint(AppTheme.color.accent.primary)
        .echoToasts(toasts)
        .sheet(item: $openedAlert) { alert in

            AdminAlertSheet(alert: alert, onOpenTarget: { open(target: $0) })
        }
        .task(id: environment.push.pendingTarget) { await openPendingAlert() }
    }

    private var gate: some View {
        VStack(spacing: AppTheme.space.lg) {
            EchoRippleMark(systemImage: "lock.shield")
            Text("admin.gate.title").echoTextStyle(.title2)
            Text("admin.gate.message")
                .echoTextStyle(.body)
                .foregroundStyle(AppTheme.color.content.secondary)
                .multilineTextAlignment(.center)
            EchoButton("admin.gate.unlock", leadingIcon: "faceid") { Task { await unlock() } }
            EchoButton("settings.signOut", variant: .ghost, size: .sm) { Task { await environment.signOut() } }
        }
        .padding(AppTheme.layout.screenHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
        .task { await unlock() }
    }

    private func unlock() async {
        unlocked = await environment.appLock.confirmOwner(reason: String(localized: "admin.gate.reason"))
    }

    /// Bildirimden gelinmişse uyarı bulunup açılır; hedef ekrana uyarının içinden gidilir.
    private func openPendingAlert() async {
        guard unlocked, let target = environment.push.pendingTarget, target.type == .adminAlert else { return }
        environment.push.pendingTarget = nil
        tab = .status
        guard let alerts = try? await store.service.alerts() else { return }
        openedAlert = alerts.first { $0.id == target.id } ?? alerts.first
    }

    /// `target`: blocks, users/<id>, ai, errors, moderation ya da overview.
    private func open(target: String) {
        openedAlert = nil
        switch target {
        case "blocks": tab = .blocks
        case "ai": tab = .traffic
        case "errors": logKind = .errors; tab = .logs
        case "moderation": logKind = .reports; tab = .logs
        case let value where value.hasPrefix("users/"):
            tab = .users
            usersPath = NavigationPath([AdminUserRoute(id: String(value.dropFirst("users/".count)))])
        default: tab = .status
        }
    }
}

/// Uyarının tamamı; "Gördüm" okundu işaretler, "Ekrana git" ilgili sekmeyi açar.
struct AdminAlertSheet: View {
    let alert: AdminAPI.AdminAlertResponse
    let onOpenTarget: (String) -> Void
    @Environment(AdminStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var acknowledged = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.space.md) {
                HStack(spacing: AppTheme.space.xs) {
                    Circle().fill(AdminFormat.severityColor(alert.severity)).frame(width: 10, height: 10)
                    Text(AdminFormat.moment(alert.createdAt))
                        .echoTextStyle(.footnote)
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
                Text(verbatim: alert.title).echoTextStyle(.title3)
                Text(verbatim: alert.body)
                    .echoTextStyle(.body)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                delivery
                Spacer()
                if let target = alert.target {

                    EchoButton("admin.alert.openTarget", size: .lg, trailingIcon: "arrow.right", fullWidth: true) {
                        onOpenTarget(target)
                    }
                }
                if alert.acknowledgedAt == nil, !acknowledged {

                    EchoButton("admin.alert.acknowledge", variant: .secondary, size: .lg, fullWidth: true) {
                        Task {
                            try? await store.service.acknowledge(alertID: alert.id)
                            acknowledged = true
                            await store.refresh()
                        }
                    }
                }
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.color.bg.canvas)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("common.close") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var delivery: some View {
        HStack(spacing: AppTheme.space.xs) {
            if alert.pushSentAt != nil { EchoChip(String(localized: "admin.alert.push"), systemImage: "iphone") }
            if alert.emailSentAt != nil { EchoChip(String(localized: "admin.alert.email"), systemImage: "envelope") }
            if alert.acknowledgedAt != nil || acknowledged { EchoChip(String(localized: "admin.alert.seen"), systemImage: "checkmark") }
        }
    }
}

extension AdminAPI.AdminAlertResponse: @retroactive Identifiable {}
extension AdminAPI.AccessBlockResponse: @retroactive Identifiable {}
extension AdminAPI.AdminUserSummaryResponse: @retroactive Identifiable {}
extension AdminAPI.AdminModerationReportResponse: @retroactive Identifiable {}
extension AdminAPI.AdminAuditEntryResponse: @retroactive Identifiable {}
extension AdminAPI.AdminErrorResponse: @retroactive Identifiable {}
