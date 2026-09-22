import SwiftUI
import EchoAdminContract

/// Durum: sağlık, bugünün sayıları, AI harcaması, kapatma anahtarları ve son uyarılar. 30 saniyede bir yenilenir.
struct AdminStatusView: View {
    let onOpenAlert: (AdminAPI.AdminAlertResponse) -> Void
    @Environment(AppEnvironment.self) private var environment
    @Environment(AdminStore.self) private var store
    @Environment(EchoToastCenter.self) private var toasts
    @State private var pending: AdminPendingAction?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                if let error = store.error, store.overview == nil {

                    EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.network"))
                }
                if let overview = store.overview {

                    health(overview)
                    numbers(overview)
                    ai(overview.ai)
                    controls(overview.controls)
                    alerts(overview)
                } else if store.error == nil {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.vertical, AppTheme.space.md)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("admin.tab.status"))
        .toolbar { ToolbarItem(placement: .topBarTrailing) { menu } }
        .echoRefreshable { await store.refresh() }
        .task {
            while !Task.isCancelled {

                await store.refresh()
                try? await Task.sleep(for: .seconds(30))
            }
        }
        .task {
            // Uyarıların telefona gelmesi için izin panelin ilk açılışında istenir.
            if let userID = environment.session.state.user?.id { await environment.push.requestAuthorization(userID: userID) }
        }
        .sheet(item: $pending) { action in

            AdminConfirmSheet(action: action) { toasts.show(.init($0, systemImage: "checkmark")) }
        }
    }

    private var menu: some View {
        Menu {
            Button("admin.status.testAlert", systemImage: "bell.badge") {
                Task {
                    if (try? await store.service.sendTestAlert()) != nil {

                        toasts.show(.init(String(localized: "admin.status.testAlertSent"), systemImage: "paperplane"))
                        await store.refresh()
                    }
                }
            }
            Button("settings.signOut", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                Task { await environment.signOut() }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func health(_ overview: AdminAPI.AdminOverviewResponse) -> some View {
        let system = overview.system
        let traffic = overview.lastHour
        return EchoCard {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                HStack {
                    Text("admin.status.health").echoTextStyle(.headline)
                    Spacer()
                    Text(AdminFormat.ago(overview.generatedAt))
                        .echoTextStyle(.caption)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
                healthRow("admin.status.database", ok: system.dbReachable, value: system.dbReachable ? "OK" : "DOWN")
                healthRow("admin.status.queue", ok: overview.queueWaiting < 50, value: AdminFormat.count(overview.queueWaiting))
                healthRow("admin.status.errors24h", ok: system.errors24h < 10, value: AdminFormat.count(system.errors24h))
                healthRow("admin.status.requestsHour", ok: traffic.serverErrors == 0,
                          value: "\(AdminFormat.count(traffic.requests)) · 5xx \(traffic.serverErrors) · 429 \(traffic.limited)")
                if overview.autoBlocks > 0 {

                    healthRow("admin.status.autoBlocks", ok: false, value: AdminFormat.count(overview.autoBlocks))
                }
            }
        }
    }

    private func healthRow(_ title: LocalizedStringKey, ok: Bool, value: String) -> some View {
        HStack {
            Circle().fill(ok ? AppTheme.color.feedback.success : AppTheme.color.feedback.warning).frame(width: 8, height: 8)
            Text(title).echoTextStyle(.subhead)
            Spacer()
            Text(verbatim: value)
                .echoTextStyle(.subhead).monospacedDigit()
                .foregroundStyle(AppTheme.color.content.secondary)
        }
    }

    private func numbers(_ overview: AdminAPI.AdminOverviewResponse) -> some View {
        let system = overview.system
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.space.xs) {
            stat("admin.status.users", AdminFormat.count(system.totalUsers), detail: "+\(system.newUsers24h)")
            stat("admin.status.activeToday", AdminFormat.count(system.activeToday), detail: nil)
            stat("admin.status.entries24h", AdminFormat.count(system.entries24h), detail: system.failedEntries > 0 ? "✕ \(system.failedEntries)" : nil)
            stat("admin.status.pushTokens", AdminFormat.count(system.activePushTokens), detail: nil)
        }
    }

    private func stat(_ title: LocalizedStringKey, _ value: String, detail: String?) -> some View {
        EchoCard(padding: AppTheme.layout.cardPaddingCompact) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                Text(title).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.secondary)
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.space.xxs) {
                    Text(verbatim: value).echoTextStyle(.title2).monospacedDigit()
                    if let detail {

                        Text(verbatim: detail).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func ai(_ ai: AdminAPI.AdminAiStatus) -> some View {
        EchoCard {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                HStack {
                    Text("admin.status.ai").echoTextStyle(.headline)
                    Spacer()
                    EchoChip(ai.provider)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: AdminFormat.lira(ai.monthTry)).echoTextStyle(.title2).monospacedDigit()
                    Text(verbatim: "/ \(AdminFormat.lira(ai.monthBudgetTry))")
                        .echoTextStyle(.subhead)
                        .foregroundStyle(AppTheme.color.content.secondary)
                    Spacer()
                    Text(verbatim: "%\(ai.monthPercent)").echoTextStyle(.subhead).monospacedDigit()
                }
                ProgressView(value: Double(min(ai.monthPercent, 100)), total: 100)
                    .tint(ai.monthPercent >= 80 ? AppTheme.color.feedback.warning : AppTheme.color.accent.primary)
                Text(String(format: String(localized: "admin.status.aiToday"), AdminFormat.lira(ai.todayTry)))
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
                let open = ai.circuits.filter { $0.state != "closed" && $0.state != "disabled" }
                if !open.isEmpty {

                    ForEach(open, id: \.name) { circuit in

                        Label("\(circuit.name): \(circuit.state)", systemImage: "bolt.trianglebadge.exclamationmark")
                            .echoTextStyle(.footnote)
                            .foregroundStyle(AppTheme.color.feedback.danger)
                    }
                }
            }
        }
    }

    private func controls(_ controls: [AdminAPI.AdminControlResponse]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.status.switches")
            VStack(spacing: 0) {
                ForEach(Array(controls.enumerated()), id: \.element.key) { index, control in

                    controlRow(control)
                    if index < controls.count - 1 { EchoDivider() }
                }
            }
            .background(RoundedRectangle(cornerRadius: AppTheme.radius.lg, style: .continuous).fill(AppTheme.color.bg.surface))
        }
    }

    private func controlRow(_ control: AdminAPI.AdminControlResponse) -> some View {
        HStack(alignment: .top, spacing: AppTheme.space.xs) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                Text(verbatim: AdminFormat.controlTitle(control.key)).echoTextStyle(.bodyEmphasis)
                Text(verbatim: control.enabled ? (control.message ?? control.defaultMessage) : control.defaultMessage)
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .lineLimit(2)
                if control.enabled, let by = control.updatedBy, let at = control.updatedAt {

                    Text(verbatim: "\(by) · \(AdminFormat.ago(at))")
                        .echoTextStyle(.caption)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(get: { control.enabled }, set: { pending = toggle(control, to: $0) }))
                .labelsHidden()
                .tint(AppTheme.color.feedback.danger)
        }
        .padding(AppTheme.space.sm)
    }

    private func toggle(_ control: AdminAPI.AdminControlResponse, to enabled: Bool) -> AdminPendingAction {
        let service = store.service
        let store = store
        let title = String(format: String(localized: enabled ? "admin.control.turnOn" : "admin.control.turnOff"),
                           AdminFormat.controlTitle(control.key))
        return AdminPendingAction(title: title, message: control.defaultMessage, asksNotice: enabled, destructive: enabled) { input in
            let controls = try await service.setControl(key: control.key, enabled: enabled, message: input.message, reason: input.reason)
            store.apply(controls: controls)
        }
    }

    private func alerts(_ overview: AdminAPI.AdminOverviewResponse) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.status.alerts") {
                if overview.unacknowledgedAlerts > 0 {

                    EchoBadge(count: Int(overview.unacknowledgedAlerts))
                }
            }
            if overview.alerts.isEmpty {

                Text("admin.status.noAlerts")
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
            }
            ForEach(overview.alerts) { alert in

                AdminAlertRow(alert: alert).echoRowButton { onOpenAlert(alert) }
            }
        }
    }
}

struct AdminAlertRow: View {
    let alert: AdminAPI.AdminAlertResponse

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.space.xs) {
            Circle()
                .fill(AdminFormat.severityColor(alert.severity))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
                Text(verbatim: alert.title)
                    .echoTextStyle(.subhead)
                    .fontWeight(alert.acknowledgedAt == nil ? .semibold : .regular)
                    .foregroundStyle(AppTheme.color.content.primary)
                Text(verbatim: alert.body)
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: AppTheme.space.xs)
            Text(AdminFormat.ago(alert.createdAt))
                .echoTextStyle(.caption)
                .foregroundStyle(AppTheme.color.content.tertiary)
        }
        .padding(.vertical, AppTheme.space.xxs)
        .contentShape(Rectangle())
    }
}
