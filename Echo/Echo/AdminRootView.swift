import SwiftUI

struct AdminRootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locManager: LocalizationManager
    @StateObject private var viewModel = AdminMonitorViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        if viewModel.isLoading && viewModel.summary == nil {
                            ProgressView()
                                .padding(.top, AppTheme.Spacing.xxl)
                        } else if viewModel.summary == nil, let message = viewModel.errorMessage {
                            ErrorStateView(message: message) {
                                Task { await viewModel.load() }
                            }
                            .padding(.top, AppTheme.Spacing.xxl)
                        } else if let summary = viewModel.summary {
                            healthBanner(for: summary)
                            metricGroups(for: summary)
                            errorsSection
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
                .refreshable { await viewModel.load() }
            }
        }
        .onAppear {
            if viewModel.summary == nil {
                Task { await viewModel.load() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(locManager.t("admin.title"))
                    .font(AppTheme.Typography.heading2)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                if let generatedAt = viewModel.summary?.generatedAt {
                    Text(locManager.t("admin.updated") + " " + shortTime(generatedAt))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }
            Spacer()
            Button(action: { Task { await viewModel.load() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(width: 36, height: 36)
            }
            Button(action: { appState.signOut() }) {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.destructive)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    // MARK: - Health banner

    private func healthBanner(for summary: AdminSummary) -> some View {
        let level = AdminHealth.evaluate(summary)
        return HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(level.color)
                .frame(width: 12, height: 12)
            Text(locManager.t(level.labelKey))
                .font(AppTheme.Typography.bodyEm)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Spacer()
            if !summary.dbReachable {
                Text(locManager.t("admin.db_unreachable"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.destructive)
            }
        }
        .padding(AppTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(level.color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius)
                .strokeBorder(level.color.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(AppTheme.Layout.cardRadius)
    }

    // MARK: - Metric groups

    @ViewBuilder
    private func metricGroups(for summary: AdminSummary) -> some View {
        group(locManager.t("admin.section_users"), tiles: [
            MetricTile(label: locManager.t("admin.total_users"), value: summary.totalUsers),
            MetricTile(label: locManager.t("admin.active_today"), value: summary.activeToday),
            MetricTile(label: locManager.t("admin.new_24h"), value: summary.newUsers24h),
            MetricTile(label: locManager.t("admin.new_7d"), value: summary.newUsers7d)
        ])

        group(locManager.t("admin.section_content"), tiles: [
            MetricTile(label: locManager.t("admin.total_entries"), value: summary.totalEntries),
            MetricTile(label: locManager.t("admin.entries_24h"), value: summary.entries24h),
            MetricTile(label: locManager.t("admin.stuck_entries"), value: summary.stuckEntries,
                       status: summary.stuckEntries > 0 ? .warn : .ok),
            MetricTile(label: locManager.t("admin.failed_entries"), value: summary.failedEntries,
                       status: summary.failedEntries > 0 ? .warn : .ok)
        ])

        group(locManager.t("admin.section_notifications"), tiles: [
            MetricTile(label: locManager.t("admin.push_sent_24h"), value: summary.pushSent24h),
            MetricTile(label: locManager.t("admin.push_failed_24h"), value: summary.pushFailed24h,
                       status: pushFailedStatus(summary.pushFailed24h)),
            MetricTile(label: locManager.t("admin.push_skipped_24h"), value: summary.pushSkipped24h),
            MetricTile(label: locManager.t("admin.push_pending"), value: summary.pushPending),
            MetricTile(label: locManager.t("admin.active_tokens"), value: summary.activePushTokens)
        ])

        group(locManager.t("admin.section_reliability"), tiles: [
            MetricTile(label: locManager.t("admin.errors_24h"), value: summary.errors24h,
                       status: summary.errors24h > 0 ? .critical : .ok),
            MetricTile(label: locManager.t("admin.dlq_unresolved"), value: summary.dlqUnresolved,
                       status: summary.dlqUnresolved > 0 ? .warn : .ok),
            MetricTile(label: locManager.t("admin.active_subscriptions"), value: summary.activeSubscriptions)
        ])
    }

    private func group(_ title: String, tiles: [MetricTile]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: AppTheme.Spacing.sm) {
                ForEach(tiles) { tile in
                    tile
                }
            }
        }
    }

    // MARK: - Errors section

    private var errorsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(locManager.t("admin.errors_title").uppercased())
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            if viewModel.errors.isEmpty {
                EmptyStateView(
                    icon: "checkmark.seal.fill",
                    title: locManager.t("admin.no_errors"),
                    subtitle: locManager.t("admin.no_errors_sub")
                )
                .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.errors) { error in
                        AdminErrorRow(error: error)
                            .onAppear {
                                if error.id == viewModel.errors.last?.id && viewModel.canLoadMore {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                    }
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, AppTheme.Spacing.sm)
                    }
                }
            }
        }
    }

    private func pushFailedStatus(_ count: Int) -> AdminHealth {
        if count >= AdminHealth.pushFailedCritical {

            return .critical
        }
        return count > 0 ? .warn : .ok
    }

    private func shortTime(_ iso: String) -> String {
        // "2026-06-05T12:00:23.123Z" → "2026-06-05 12:00"
        String(iso.replacingOccurrences(of: "T", with: " ").prefix(16))
    }
}

// MARK: - Health level

private enum AdminHealth {
    case ok, warn, critical

    static let pushFailedCritical = 10

    var color: Color {
        switch self {
        case .ok: return AppTheme.Colors.success
        case .warn: return AppTheme.Colors.warning
        case .critical: return AppTheme.Colors.destructive
        }
    }

    var labelKey: String {
        switch self {
        case .ok: return "admin.health_ok"
        case .warn: return "admin.health_warn"
        case .critical: return "admin.health_critical"
        }
    }

    static func evaluate(_ s: AdminSummary) -> AdminHealth {
        if !s.dbReachable || s.errors24h > 0 || s.pushFailed24h >= pushFailedCritical {

            return .critical
        }
        if s.dlqUnresolved > 0 || s.stuckEntries > 0 || s.pushFailed24h > 0 || s.failedEntries > 0 {

            return .warn
        }
        return .ok
    }
}

// MARK: - Metric tile

private struct MetricTile: View, Identifiable {
    let label: String
    let value: Int
    var status: AdminHealth?
    @Environment(\.colorScheme) var colorScheme

    var id: String { label }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: 6) {
                if let status {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                }
                Text("\(value)")
                    .font(AppTheme.Typography.heading2)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
            Text(label)
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(AppTheme.Layout.cardPadding)
        .echoCard(colorScheme)
    }
}

// MARK: - Error row

private struct AdminErrorRow: View {
    let error: AdminError
    @EnvironmentObject private var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(statusBadge)
                    .font(AppTheme.Typography.label).fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.Colors.destructive)
                    .cornerRadius(AppTheme.Spacing.radiusSm)
                Text(error.exceptionClass ?? error.errorCode ?? "Error")
                    .font(AppTheme.Typography.bodyEm)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .lineLimit(1)
                Spacer()
            }

            if let path = error.path {
                Text("\(error.method ?? "") \(path)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                if let occurredAt = error.occurredAt {
                    Text(String(occurredAt.replacingOccurrences(of: "T", with: " ").prefix(19)))
                }
                if let requestId = error.requestId, !requestId.isEmpty {
                    Text("· " + requestId)
                        .lineLimit(1)
                }
            }
            .font(AppTheme.Typography.label)
            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Layout.cardPadding)
        .echoCard(colorScheme)
    }

    private var statusBadge: String {
        if let status = error.httpStatus {

            return "\(status)"
        }
        return error.severity ?? "ERR"
    }
}
