import SwiftUI
import EchoAdminContract

/// Şikâyet kuyruğu, uyarı geçmişi, denetim kaydı ve son 24 saatin sunucu hataları.
struct AdminLogsView: View {
    @Binding var kind: AdminLogKind
    let onOpenAlert: (AdminAPI.AdminAlertResponse) -> Void
    @Environment(AdminStore.self) private var store
    @Environment(EchoToastCenter.self) private var toasts
    @State private var reports: [AdminAPI.AdminModerationReportResponse] = []
    @State private var alerts: [AdminAPI.AdminAlertResponse] = []
    @State private var audit: [AdminAPI.AdminAuditEntryResponse] = []
    @State private var errors: [AdminAPI.AdminErrorResponse] = []
    @State private var error: AppError?
    @State private var resolving: AdminAPI.AdminModerationReportResponse?

    var body: some View {
        List {
            EchoSegmentedControl(selection: $kind, options: [
                .init(.reports, String(localized: "admin.logs.reports")),
                .init(.alerts, String(localized: "admin.logs.alerts")),
                .init(.audit, String(localized: "admin.logs.audit")),
                .init(.errors, String(localized: "admin.logs.errors"))
            ])
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            if let error {

                EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.unexpected"))
                    .listRowBackground(Color.clear)
            }
            switch kind {
            case .reports: reportRows
            case .alerts: alertRows
            case .audit: auditRows
            case .errors: errorRows
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("admin.tab.logs"))
        .task(id: kind) { await load() }
        .echoRefreshable { await load() }
        .confirmationDialog(Text("admin.reports.resolve"), isPresented: Binding(get: { resolving != nil }, set: { if !$0 { resolving = nil } }),
                            presenting: resolving) { report in
            Button("admin.reports.remove", role: .destructive) { Task { await resolve(report, action: "remove_content") } }
            Button("admin.reports.dismiss") { Task { await resolve(report, action: "dismiss") } }
        }
    }

    @ViewBuilder private var reportRows: some View {
        if reports.isEmpty { Text("admin.reports.none").foregroundStyle(AppTheme.color.content.secondary) }
        ForEach(reports) { report in

            VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                HStack {
                    EchoChip(report.reason)
                    Text(verbatim: "\(report.openReporterCount)×").echoTextStyle(.caption).monospacedDigit()
                    Spacer()
                    Text(AdminFormat.ago(report.createdAt)).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                }
                if let excerpt = report.targetExcerpt {

                    Text(verbatim: excerpt).echoTextStyle(.subhead).lineLimit(3)
                }
                if let details = report.details {

                    Text(verbatim: details).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                }
            }
            .padding(.vertical, AppTheme.space.xxxs)
            .echoRowButton { resolving = report }
            .listRowBackground(AppTheme.color.bg.surface)
        }
    }

    @ViewBuilder private var alertRows: some View {
        if alerts.isEmpty { Text("admin.status.noAlerts").foregroundStyle(AppTheme.color.content.secondary) }
        ForEach(alerts) { alert in

            AdminAlertRow(alert: alert).echoRowButton { onOpenAlert(alert) }
                .listRowBackground(AppTheme.color.bg.surface)
        }
    }

    @ViewBuilder private var auditRows: some View {
        ForEach(audit) { entry in

            VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
                HStack {
                    Text(verbatim: entry.action).echoTextStyle(.subhead).monospaced()
                    Spacer()
                    Text(AdminFormat.ago(entry.createdAt)).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                }
                Text(verbatim: [entry.targetId, entry.reason].compactMap { $0 }.joined(separator: " · "))
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.content.secondary)
                    .lineLimit(2)
                Text(verbatim: entry.adminEmail ?? String(localized: "admin.logs.automatic"))
                    .echoTextStyle(.caption)
                    .foregroundStyle(AppTheme.color.content.tertiary)
            }
            .listRowBackground(AppTheme.color.bg.surface)
        }
    }

    @ViewBuilder private var errorRows: some View {
        if errors.isEmpty { Text("admin.logs.noErrors").foregroundStyle(AppTheme.color.content.secondary) }
        ForEach(errors) { entry in

            VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
                HStack {
                    Text(verbatim: entry.errorCode ?? entry.severity).echoTextStyle(.subhead).monospaced()
                    if let status = entry.httpStatus { Text(verbatim: "\(status)").echoTextStyle(.caption) }
                    Spacer()
                    Text(AdminFormat.ago(entry.occurredAt)).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                }
                Text(verbatim: [entry.method, entry.path].compactMap { $0 }.joined(separator: " "))
                    .echoTextStyle(.caption).monospaced()
                    .foregroundStyle(AppTheme.color.content.secondary)
                if let message = entry.shortMessage {

                    Text(verbatim: message).echoTextStyle(.footnote).lineLimit(3).textSelection(.enabled)
                }
            }
            .listRowBackground(AppTheme.color.bg.surface)
        }
    }

    private func load() async {
        do {
            switch kind {
            case .reports: reports = try await store.service.reports()
            case .alerts: alerts = try await store.service.alerts()
            case .audit: audit = try await store.service.audit()
            case .errors: errors = try await store.service.errors()
            }
            error = nil
        } catch {
            if let shown = AppError.displayable(error) { self.error = shown }
        }
    }

    private func resolve(_ report: AdminAPI.AdminModerationReportResponse, action: String) async {
        do {
            try await store.service.resolveReport(id: report.id, action: action)
            toasts.show(.init(String(localized: "admin.reports.resolved"), systemImage: "checkmark"))
            await load()
        } catch {
            self.error = AppError.displayable(error)
        }
    }
}
