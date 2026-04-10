import SwiftUI

struct CoachSessionsListView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @StateObject private var viewModel = CoachViewModel()
    @State private var isMenuOpen       = false
    @State private var isCreating       = false
    @State private var createError:     String?
    @State private var selectedSession: APICoachSession?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(AppTheme.Colors.accent.opacity(0.07))
                .blur(radius: 80)
                .frame(width: 300, height: 300)
                .offset(x: -60, y: -80)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen.toggle() } }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)

                    Spacer()

                    Text(locManager.t("hamburger.ai_coach"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))

                    Spacer()

                    Button(action: startNewSession) {
                        ZStack {
                            if isCreating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.7)
                            } else {
                                Image(systemName: "plus").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Gradients.accent)
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                    .disabled(isCreating)
                }
                .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                .padding(.top, AppTheme.Layout.headerTop)
                .padding(.bottom, AppTheme.Layout.headerBottom)

                if viewModel.isLoadingSessions {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if viewModel.sessions.isEmpty {
                    if let error = viewModel.listError {
                        ErrorStateView(message: error) {
                            viewModel.loadSessions()
                        }
                    } else {
                        emptyState
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            if let error = viewModel.listError {
                                InlineBannerView(message: error, type: .error) {
                                    viewModel.listError = nil
                                }
                                .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                            }
                            // Featured bento card
                            featuredCard

                            // Session list header
                            HStack {
                                Text(locManager.t("coach.recent_sessions"))
                                    .font(AppTheme.Typography.caption).fontWeight(.bold)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Layout.screenHorizontal)

                            LazyVStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(viewModel.sessions) { session in
                                    SessionRowView(session: session)
                                        .onTapGesture { selectedSession = session }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                viewModel.deleteSession(id: session.id)
                                            } label: {
                                                Label(locManager.t("common.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                                if viewModel.hasMorePages {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                                        .padding(.vertical, AppTheme.Spacing.sm)
                                        .onAppear { viewModel.loadMoreSessions() }
                                }
                            }
                            .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                        }
                        .padding(.top, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }

            if isMenuOpen {
                HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                    .ignoresSafeArea()
            }

            if let err = createError {
                VStack {
                    Spacer()
                    Text(err)
                        .font(AppTheme.Typography.caption).foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.md).padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.destructive.opacity(0.85))
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity)).zIndex(2)
            }
        }
        .onAppear {
            viewModel.loadSessions()
            handlePendingJournalContext()
        }
        .onDisappear {
            viewModel.cancelAll()
        }
        .navigationDestination(item: $selectedSession) { session in
            ReflectionCoachView(sessionId: session.id, viewModel: viewModel)
        }
    }

    // MARK: - Featured Bento Card

    private var featuredCard: some View {
        Button(action: startNewSession) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(locManager.t("coach.breakthrough"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(.white)
                        .lineSpacing(2)

                    Text(locManager.t("coach.start_new_session"))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.3))
                        .blur(radius: 12)
                        .frame(width: 60, height: 60)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                Color(red: 0.153, green: 0.102, blue: 0.200).opacity(0.6)
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(AppTheme.Spacing.radiusLg)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .strokeBorder(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1))
        }
        .padding(.horizontal, AppTheme.Layout.screenHorizontal)
        .disabled(isCreating)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.Colors.accentSoft(colorScheme)).frame(width: 100, height: 100)
                Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 40)).foregroundColor(AppTheme.Colors.accent)
            }
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(locManager.t("coach.no_sessions"))
                    .font(AppTheme.Typography.heading3).foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Text(locManager.t("coach.no_sessions_sub"))
                    .font(AppTheme.Typography.caption).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Button(action: startNewSession) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if isCreating {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                        Text(locManager.t("coach.new_session")).font(AppTheme.Typography.bodyEm)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.sm + 6)
                .background(AppTheme.Gradients.accent)
                .cornerRadius(AppTheme.Spacing.radiusLg - 2)
            }
            .disabled(isCreating)
            Spacer()
        }
    }

    // MARK: - Actions

    private func startNewSession() {
        guard !isCreating else { return }
        isCreating = true; createError = nil
        Task {
            do {
                let session = try await viewModel.createNewSession()
                selectedSession = session
            } catch {
                createError = error.localizedDescription
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                createError = nil
            }
            isCreating = false
        }
    }

    private func handlePendingJournalContext() {
        guard let journalId = CoachJournalContext.shared.pendingJournalEntryId else { return }
        CoachJournalContext.shared.pendingJournalEntryId = nil
        isCreating = true
        Task {
            do {
                let session = try await viewModel.createSessionWithJournal(journalEntryId: journalId)
                selectedSession = session
            } catch {
                createError = error.localizedDescription
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                createError = nil
            }
            isCreating = false
        }
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: APICoachSession
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.accent)
                    .frame(width: 48, height: 48)
                Image(systemName: session.journalEntryId != nil ? "doc.text" : "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(localizedCoachSessionTitle(session.title, locManager: locManager))
                        .font(AppTheme.Typography.bodyEm)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        .lineLimit(1)
                    if session.isActive {
                        Circle().fill(AppTheme.Colors.success).frame(width: 7, height: 7)
                    }
                }
                HStack(spacing: 6) {
                    Text(relativeDate(session.updatedAt))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    if session.journalEntryId != nil {
                        HStack(spacing: 3) {
                            Image(systemName: "book").font(.system(size: 10))
                            Text(locManager.t("nav.journal")).font(AppTheme.Typography.micro).fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(AppTheme.Colors.accentSoft(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusSm)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
        .background(AppTheme.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg - 2)
    }

    private func relativeDate(_ iso: String) -> String {
        guard let date = CoachDateParser.parse(iso) else { return locManager.t("coach.just_now") }
        let diff = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: Date())
        if let day = diff.day, day >= 2  { return "\(day) \(locManager.t("coach.days_ago"))" }
        if let day = diff.day, day == 1  { return locManager.t("coach.yesterday") }
        if let hour = diff.hour, hour >= 1 { return "\(hour) \(locManager.t("coach.hours_ago"))" }
        if let min = diff.minute, min >= 1  { return "\(min) \(locManager.t("coach.minutes_ago"))" }
        return locManager.t("coach.just_now")
    }
}

func localizedCoachSessionTitle(_ rawTitle: String?, locManager: LocalizationManager) -> String {
    guard let rawTitle else { return locManager.t("coach.session_fallback") }

    let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return locManager.t("coach.session_fallback") }

    if trimmed.compare("New Conversation", options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
        return locManager.t("coach.title_new_conversation")
    }

    if trimmed.range(of: "Journal Discussion", options: [.caseInsensitive, .diacriticInsensitive]) != nil {
        return trimmed.replacingOccurrences(
            of: "Journal Discussion",
            with: locManager.t("coach.title_journal_discussion"),
            options: [.caseInsensitive, .diacriticInsensitive],
            range: nil
        )
    }

    return trimmed
}
