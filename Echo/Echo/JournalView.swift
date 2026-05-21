import SwiftUI

struct JournalView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = JournalViewModel()
    @State private var searchText = ""
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    private var filtered: [APIJournalEntry] {
        searchText.isEmpty ? viewModel.entries :
            viewModel.entries.filter {
                ($0.analysis?.summary ?? $0.transcript ?? "").localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    AppScreenHeader(title: locManager.t("nav.journal"))

                    // Search bar
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        TextField(locManager.t("journal.search_placeholder"), text: $searchText)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusMd)
                    .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                    .padding(.bottom, AppTheme.Spacing.md)

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                        Spacer()
                    } else if filtered.isEmpty {
                        if let error = viewModel.errorMessage, viewModel.entries.isEmpty {
                            ErrorStateView(message: error) {
                                viewModel.loadRecent()
                            }
                        } else {
                            emptyState
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(filtered, id: \.id) { entry in
                                    NavigationLink(destination: JournalDetailView(entry: entry, selectedTab: $selectedTab)) {
                                        APIJournalEntryCard(entry: entry)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                            .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .onAppear { viewModel.loadRecent() }
            .onDisappear { viewModel.cancelAll() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.Colors.accentSoft(colorScheme)).frame(width: 80, height: 80)
                Image(systemName: "book.fill").font(.system(size: 32)).foregroundColor(AppTheme.Colors.accent)
            }
                Text(searchText.isEmpty ? locManager.t("journal.empty_title") : locManager.t("journal.no_results_title"))
                .font(AppTheme.Typography.heading3).foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            Text(searchText.isEmpty ? locManager.t("journal.empty_subtitle") : locManager.t("journal.no_results_subtitle"))
                .font(AppTheme.Typography.body).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .multilineTextAlignment(.center).padding(.horizontal, AppTheme.Spacing.xl)
            if searchText.isEmpty {
                Button(action: { selectedTab = "home" }) {
                    Text(locManager.t("journal.record_now"))
                        .font(AppTheme.Typography.bodyEm).foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.xl).padding(.vertical, AppTheme.Spacing.sm + 4)
                        .background(AppTheme.Gradients.accent)
                        .cornerRadius(AppTheme.Spacing.radiusFull)
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            Spacer()
        }
    }
}

// MARK: - Journal Entry Card

struct APIJournalEntryCard: View {
    let entry: APIJournalEntry
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {

            // Row 1: datetime + ellipsis
            HStack {
                Text(entry.formattedDatetime)
                    .font(AppTheme.Typography.label).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                Spacer()
            }

            // Row 2: duration pill (left) + mood pill (right)
            HStack(spacing: AppTheme.Spacing.sm) {
                if !entry.formattedDuration.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "waveform").font(.system(size: 10))
                        Text(entry.formattedDuration.uppercased())
                            .font(AppTheme.Typography.label).fontWeight(.semibold)
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.accentSoft(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                }

                Spacer()

                if entry.entryStatus == .complete, let analysis = entry.analysis {
                    HStack(spacing: 5) {
                        Circle().fill(entry.emotionalState.color).frame(width: 7, height: 7)
                        Text(locManager.t(analysis.moodLocalizationKey))
                            .font(AppTheme.Typography.label).fontWeight(.semibold)
                            .foregroundColor(entry.emotionalState.color)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(entry.emotionalState.color.opacity(0.12))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                } else {
                    Text(entry.statusLocalizationKey.map { locManager.t($0) } ?? entry.humanizedStatus)
                        .font(AppTheme.Typography.label).fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 4)
                        .background(AppTheme.Colors.accentSoft(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusFull)
                }
            }

            // Row 3: summary preview
            Text(entry.analysis?.summary ?? entry.transcript ?? locManager.t("journal.status.processing"))
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                .lineLimit(2)
                .lineSpacing(2)

            if entry.entryStatus == .complete {
                Divider().background(AppTheme.Colors.borderSubtle(colorScheme))
                HStack(spacing: 5) {
                    Image(systemName: "sparkles").font(.system(size: 10))
                    Text(locManager.t("journal.ai_insight_ready"))
                        .font(AppTheme.Typography.label).fontWeight(.bold)
                }
                .foregroundColor(AppTheme.Colors.success)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
            .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
    }
}
