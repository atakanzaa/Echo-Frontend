import SwiftUI

struct TimeCapsuleView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = TimeCapsuleViewModel()
    @State private var isMenuOpen = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager

    var body: some View {
        ZStack {
            // Special gradient background for the mystical capsule feel
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.298, green: 0.114, blue: 0.584), location: 0.0),
                    .init(color: Color(red: 0.200, green: 0.090, blue: 0.361), location: 0.3),
                    .init(color: Color(red: 0.149, green: 0.075, blue: 0.247), location: 0.45),
                    .init(color: AppTheme.Colors.background(colorScheme), location: 0.6)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image(systemName: "sparkles").font(.system(size: 100))
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme)).opacity(0.05).offset(x: -100, y: -100)

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.time_capsule"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: .home)
                    },
                    showMenu: true,
                    onMenu: { isMenuOpen.toggle() }
                )

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.capsules.isEmpty {
                    ErrorStateView(message: error) {
                        viewModel.loadCapsules()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Countdown Section
                            VStack(spacing: AppTheme.Spacing.xl) {
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text(locManager.t("capsule.next_opening"))
                                        .font(AppTheme.Typography.caption).fontWeight(.medium)
                                        .tracking(1.4)
                                        .foregroundColor(AppTheme.Colors.accentSecondary)

                                    Text(viewModel.nextUnlockCountdown)
                                        .font(AppTheme.Typography.display)
                                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                        .shadow(color: AppTheme.Colors.accent.opacity(0.5), radius: 15)
                                }

                                // Central Lock Icon
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.Colors.accent.opacity(0.3))
                                        .blur(radius: 30).frame(width: 192, height: 192)
                                    Circle()
                                        .strokeBorder(AppTheme.Colors.textPrimary(colorScheme).opacity(0.1), lineWidth: 1)
                                        .frame(width: 192, height: 192)
                                    VStack {
                                        Image(systemName: "lock.fill").font(.system(size: 40))
                                            .foregroundColor(AppTheme.Colors.accentSecondary)
                                            .shadow(color: AppTheme.Colors.accentSecondary.opacity(0.8), radius: 10)
                                        Text(locManager.t("capsule.sealed").uppercased())
                                            .font(AppTheme.Typography.micro).fontWeight(.bold)
                                            .tracking(2.4)
                                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.5))
                                    }
                                }
                                .frame(height: 200)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)

                            // Sealed Memories Section
                            if !viewModel.capsules.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    HStack {
                                        Text(locManager.t("capsule.sealed_memories"))
                                            .font(AppTheme.Typography.heading3)
                                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                        Spacer()
                                        Text(String(format: locManager.t("capsule.pending_fmt"), viewModel.capsules.filter(\.isSealed).count))
                                            .font(AppTheme.Typography.caption).fontWeight(.semibold)
                                            .foregroundColor(AppTheme.Colors.accentSecondary)
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.lg)

                                    VStack(spacing: AppTheme.Spacing.sm) {
                                        ForEach(viewModel.capsules) { capsule in
                                            APISealedMemoryCard(capsule: capsule)
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.lg)
                                }
                            }

                            // Record Button
                            Button(action: { viewModel.showCreateSheet = true }) {
                                HStack {
                                    Image(systemName: "mic.fill").font(AppTheme.Typography.bodyEm)
                                    Text(locManager.t("capsule.record_future_self")).font(AppTheme.Typography.bodyEm)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(AppTheme.Gradients.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.Spacing.radiusFull)
                                .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 12, y: 4)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.xxl)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
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
        }
        .onAppear { viewModel.loadCapsules() }
        .onDisappear { viewModel.cancelAll() }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateCapsuleSheet(viewModel: viewModel)
        }
    }
}

// MARK: - API Sealed Memory Card

struct APISealedMemoryCard: View {
    let capsule: APITimeCapsule
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        let localizedContentType = CapsuleContentType(rawBackend: capsule.contentType).displayTitle

        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: capsule.isSealed ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(AppTheme.Gradients.accent)
                .cornerRadius(AppTheme.Spacing.radiusSm)

            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title ?? String(format: locManager.t("capsule.default_title_fmt"), localizedContentType))
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme)).lineLimit(1)
                Text("\(localizedContentType) • \(locManager.t("capsule.unlock")) \(capsule.unlockDateFormatted)")
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(capsule.sealedDateShort)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.5))
        .cornerRadius(AppTheme.Spacing.radiusMd)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
            .strokeBorder(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Create Capsule Sheet

struct CreateCapsuleSheet: View {
    @ObservedObject var viewModel: TimeCapsuleViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                KeyboardAwareFormScroll {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Title
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(locManager.t("capsule.title_optional"))
                            .font(AppTheme.Typography.label).fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        TextField(locManager.t("capsule.title_placeholder"), text: $viewModel.capsuleTitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                            .padding(AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.surface(colorScheme))
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                    }

                    // Unlock in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(String(format: locManager.t("capsule.unlock_days_fmt"), viewModel.unlockInDays))
                            .font(AppTheme.Typography.label).fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 72), spacing: AppTheme.Spacing.sm)],
                            spacing: AppTheme.Spacing.sm
                        ) {
                            ForEach([30, 90, 180, 365], id: \.self) { days in
                                Button(action: { viewModel.unlockInDays = days }) {
                                    Text(String(format: locManager.t("capsule.days_short_fmt"), days))
                                        .font(AppTheme.Typography.caption).fontWeight(.semibold)
                                        .foregroundColor(viewModel.unlockInDays == days
                                            ? .white : AppTheme.Colors.textMuted(colorScheme))
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.sm)
                                        .background(viewModel.unlockInDays == days
                                            ? AppTheme.Colors.accent
                                            : AppTheme.Colors.surface(colorScheme))
                                        .cornerRadius(AppTheme.Spacing.radiusSm)
                                }
                            }
                        }
                    }

                    // Record
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(locManager.t("capsule.voice_message"))
                            .font(AppTheme.Typography.label).fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        Button(action: { viewModel.toggleRecording() }) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(viewModel.isRecording ? locManager.t("capsule.recording") : locManager.t("voice.tap_to_record"))
                                        .font(AppTheme.Typography.label).fontWeight(.semibold)
                                    Text(viewModel.recordingTime).font(AppTheme.Typography.micro)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Spacing.sm)
                            .foregroundColor(viewModel.isRecording ? AppTheme.Colors.destructive : AppTheme.Colors.textPrimary(colorScheme))
                            .background(viewModel.isRecording
                                ? AppTheme.Colors.destructive.opacity(0.2)
                                : AppTheme.Colors.surface(colorScheme))
                            .cornerRadius(AppTheme.Spacing.radiusMd)
                        }
                    }

                    // Create Button
                    Button(action: { viewModel.createCapsule() }) {
                        if viewModel.isCreating {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(locManager.t("capsule.seal_capsule"))
                                .font(AppTheme.Typography.bodyEm).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(AppTheme.Gradients.accent)
                    .cornerRadius(AppTheme.Spacing.radiusLg)
                    .disabled(viewModel.isCreating)
                }
                .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(locManager.t("capsule.new"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(locManager.t("common.cancel")) { viewModel.showCreateSheet = false }
                        .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
    }
}
