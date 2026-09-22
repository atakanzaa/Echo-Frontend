import Charts
import SwiftUI
import EchoAdminContract

/// Trafik (son saat dakikalık, son gün saatlik), en çok istek atanlar ve AI harcaması.
/// Sayaçlar sunucu belleğindedir; deploy sonrası sıfırdan başlar.
struct AdminTrafficView: View {
    @Environment(AdminStore.self) private var store
    @Environment(EchoToastCenter.self) private var toasts
    @State private var window = "1h"
    @State private var traffic: AdminAPI.AdminTrafficResponse?
    @State private var usage: AdminAPI.AdminAiUsageResponse?
    @State private var error: AppError?
    @State private var pending: AdminPendingAction?
    @State private var newBlock: AdminBlockDraft?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                EchoSegmentedControl(selection: $window, options: [.init("1h", String(localized: "admin.traffic.hour")),
                                                                   .init("24h", String(localized: "admin.traffic.day"))])
                if let error {

                    EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.unexpected"))
                }
                if let traffic {

                    chart(traffic)
                    callers(traffic.callers)
                    endpoints(traffic.endpoints)
                } else if error == nil {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
                if let ai = store.overview?.ai { provider(ai) }
                if let usage { aiMonth(usage) }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.vertical, AppTheme.space.md)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("admin.tab.traffic"))
        .navigationDestination(for: AdminUserRoute.self) { AdminUserDetailView(id: $0.id) }
        .task(id: window) { await load() }
        .echoRefreshable { await load() }
        .sheet(item: $pending) { action in

            AdminConfirmSheet(action: action) { title in
                toasts.show(.init(title, systemImage: "checkmark"))
                Task { await store.refresh() }
            }
        }
        .sheet(item: $newBlock) { draft in

            AdminNewBlockSheet(draft: draft) { toasts.show(.init($0, systemImage: "checkmark")) }
        }
    }

    private func load() async {
        do {
            async let traffic = store.service.traffic(window: window)
            async let usage = store.service.aiUsage()
            self.traffic = try await traffic
            self.usage = try await usage
            error = nil
        } catch {
            if let shown = AppError.displayable(error) { self.error = shown }
        }
    }

    private func chart(_ traffic: AdminAPI.AdminTrafficResponse) -> some View {
        let total = traffic.series.reduce(Int64(0)) { $0 + $1.requests }
        let failed = traffic.series.reduce(Int64(0)) { $0 + $1.serverErrors }
        let limited = traffic.series.reduce(Int64(0)) { $0 + $1.limited }
        return EchoCard {
            VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: AdminFormat.count(total)).echoTextStyle(.title2).monospacedDigit()
                    Text("admin.traffic.requests").echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.secondary)
                    Spacer()
                    Text(verbatim: "5xx \(failed) · 429 \(limited)")
                        .echoTextStyle(.footnote).monospacedDigit()
                        .foregroundStyle(failed > 0 ? AppTheme.color.feedback.danger : AppTheme.color.content.secondary)
                }
                Chart(traffic.series, id: \.start) { slot in

                    BarMark(x: .value("t", slot.start), y: .value("n", slot.requests - slot.serverErrors - slot.limited))
                        .foregroundStyle(AppTheme.color.accent.primary)
                    BarMark(x: .value("t", slot.start), y: .value("n", slot.limited))
                        .foregroundStyle(AppTheme.color.feedback.warning)
                    BarMark(x: .value("t", slot.start), y: .value("n", slot.serverErrors))
                        .foregroundStyle(AppTheme.color.feedback.danger)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: window == "1h" ? .dateTime.hour().minute() : .dateTime.hour())
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private func callers(_ callers: [AdminAPI.AdminCaller]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.traffic.callers")
            ForEach(callers, id: \.value) { caller in

                HStack(spacing: AppTheme.space.xs) {
                    Image(systemName: caller.kind == "user" ? "person" : "network")
                        .foregroundStyle(AppTheme.color.content.secondary)
                    VStack(alignment: .leading, spacing: AppTheme.space.xxxxs) {
                        Text(verbatim: caller.email ?? caller.value).echoTextStyle(.subhead).lineLimit(1)
                        Text(verbatim: "\(caller.requests) · 4xx \(caller.clientErrors) · 429 \(caller.limited)")
                            .echoTextStyle(.caption).monospacedDigit()
                            .foregroundStyle(caller.limited > 0 ? AppTheme.color.feedback.warning : AppTheme.color.content.secondary)
                    }
                    Spacer()
                    if caller.blocked {

                        EchoChip(String(localized: "admin.blocks.blocked"), systemImage: "hand.raised")
                    } else if let userID = caller.userId {
                        NavigationLink(value: AdminUserRoute(id: userID)) { Image(systemName: "chevron.right") }
                    } else {
                        Button("admin.blocks.block") { newBlock = AdminBlockDraft(kind: "ip", value: caller.value) }
                            .echoTextStyle(.subhead)
                    }
                }
                .padding(.vertical, AppTheme.space.xxxs)
            }
        }
    }

    private func endpoints(_ endpoints: [AdminAPI.AdminEndpointTraffic]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.traffic.endpoints")
            ForEach(endpoints.prefix(25), id: \.endpoint) { endpoint in

                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: endpoint.endpoint.replacingOccurrences(of: "/api/v1", with: ""))
                        .echoTextStyle(.caption).monospaced()
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text(verbatim: "\(endpoint.requests)")
                        .echoTextStyle(.caption).monospacedDigit()
                    if endpoint.serverErrors > 0 {

                        Text(verbatim: "5xx \(endpoint.serverErrors)").echoTextStyle(.caption)
                            .foregroundStyle(AppTheme.color.feedback.danger)
                    }
                }
            }
        }
    }

    private func provider(_ ai: AdminAPI.AdminAiStatus) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.traffic.provider")
            HStack {
                Text(verbatim: ai.provider).echoTextStyle(.bodyEmphasis)
                Spacer()
                Menu {
                    ForEach(["gemini", "openai", "claude"].filter { $0 != ai.provider }, id: \.self) { name in

                        Button(name) { pending = switchProvider(to: name) }
                    }
                } label: {
                    Text("admin.traffic.switchProvider").echoTextStyle(.subhead)
                }
            }
            ForEach(ai.circuits, id: \.name) { circuit in

                HStack {
                    Text(verbatim: circuit.name).echoTextStyle(.caption).monospaced()
                    Spacer()
                    Text(verbatim: circuit.state).echoTextStyle(.caption)
                        .foregroundStyle(circuit.state == "closed" ? AppTheme.color.content.secondary : AppTheme.color.feedback.danger)
                }
            }
        }
    }

    private func switchProvider(to name: String) -> AdminPendingAction {
        let service = store.service
        return AdminPendingAction(title: String(format: String(localized: "admin.traffic.switchTo"), name),
                                  message: String(localized: "admin.traffic.switchMessage")) { _ in
            try await service.switchProvider(name)
        }
    }

    private func aiMonth(_ usage: AdminAPI.AdminAiUsageResponse) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
            EchoSectionHeader("admin.traffic.aiMonth") {
                Text(verbatim: "\(AdminFormat.lira(usage.spentTry)) / \(AdminFormat.lira(usage.budgetTry))")
                    .echoTextStyle(.caption).monospacedDigit()
                    .foregroundStyle(AppTheme.color.content.secondary)
            }
            ForEach(usage.operations, id: \.operation) { operation in

                HStack {
                    Text(verbatim: operation.operation).echoTextStyle(.subhead)
                    Spacer()
                    Text(verbatim: "\(operation.calls)× · $\(String(format: "%.3f", Double(operation.costMicroUsd) / 1_000_000))")
                        .echoTextStyle(.caption).monospacedDigit()
                        .foregroundStyle(AppTheme.color.content.secondary)
                }
            }
            if !usage.topUsers.isEmpty {

                Text("admin.traffic.topUsers").echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                    .padding(.top, AppTheme.space.xxs)
                ForEach(usage.topUsers, id: \.userId) { user in

                    NavigationLink(value: AdminUserRoute(id: user.userId)) {
                        HStack {
                            Text(verbatim: String(user.userId.prefix(8))).echoTextStyle(.caption).monospaced()
                            Text(verbatim: user.tier).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.secondary)
                            Spacer()
                            Text(verbatim: "$\(String(format: "%.3f", Double(user.costMicroUsd) / 1_000_000))")
                                .echoTextStyle(.caption).monospacedDigit()
                        }
                    }
                    .foregroundStyle(AppTheme.color.content.primary)
                }
            }
        }
    }
}
