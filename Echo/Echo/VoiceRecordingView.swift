import SwiftUI
import AVFoundation

struct VoiceRecordingView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = HomeViewModel()
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.15
    @State private var waveHeights: [CGFloat] = Array(repeating: 0.3, count: 28)
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    // Idle wave pattern — subtle variation so bars aren't all flat
    private let idleHeights: [CGFloat] = [
        0.2, 0.35, 0.5, 0.4, 0.6, 0.45, 0.3, 0.55,
        0.65, 0.4, 0.3, 0.5, 0.7, 0.45, 0.35, 0.6,
        0.5, 0.3, 0.65, 0.4, 0.55, 0.35, 0.6, 0.45,
        0.3, 0.5, 0.4, 0.25
    ]

    var body: some View {
        NavigationStack {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            // Ambient glow
            Ellipse()
                .fill(AppTheme.Colors.accent.opacity(glowOpacity))
                .frame(width: 400, height: 300)
                .blur(radius: 80)
                .offset(y: -120)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // MARK: Main area
                if viewModel.awaitingConfirmation {
                    confirmationArea
                } else {
                    Spacer(minLength: 0)
                    micSection
                    Spacer(minLength: 0)
                }

                Spacer().frame(height: AppTheme.Spacing.sm)

                // MARK: Status pill
                statusArea
                    .padding(.bottom, AppTheme.Spacing.md)

                // MARK: On This Day
                if !viewModel.onThisDayEntries.isEmpty {
                    onThisDaySection
                }

                // MARK: Recent entries
                recentEntriesSection
                    .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
            }

        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.awaitingConfirmation)
        .safeAreaInset(edge: .top, spacing: 0) {
            fixedHeader
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            startIdleAnimation()
            waveHeights = idleHeights
            viewModel.loadRecent()
        }
        .onDisappear {
            viewModel.cancelAll()
        }
        .onChange(of: viewModel.isRecording) { _, recording in
            withAnimation(.easeInOut(duration: 0.4)) {
                glowOpacity = recording ? 0.35 : 0.15
            }
            if recording {
                startPulseAnimation()
                startWaveAnimation()
            } else {
                withAnimation(.easeInOut(duration: 0.4)) {
                    waveHeights = idleHeights
                }
            }
        }
        }
    }

    private var fixedHeader: some View {
        AppScreenHeader(title: "Echo") {
            HStack(spacing: AppTheme.Spacing.sm) {
                if viewModel.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.warning)
                        Text("\(viewModel.currentStreak) \(locManager.t("profile.days"))")
                            .font(AppTheme.Typography.label).fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(AppTheme.Colors.surface(colorScheme))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                    .overlay(Capsule().stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
                }

                Button(action: { selectedTab = "settings" }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                .frame(width: AppTheme.Layout.iconButtonSize, height: AppTheme.Layout.iconButtonSize)
            }
        }
    }

    // MARK: - Mic Section

    private var micSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Waveform — always visible
            HStack(spacing: 3) {
                ForEach(0..<28, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            viewModel.isRecording
                                ? AppTheme.Colors.accent.opacity(0.5 + Double(waveHeights[i]) * 0.5)
                                : AppTheme.Colors.accent.opacity(0.2 + Double(waveHeights[i]) * 0.15)
                        )
                        .frame(width: 3, height: 8 + waveHeights[i] * 44)
                }
            }
            .frame(height: 60)
            .animation(.easeInOut(duration: 0.08), value: waveHeights)

            // Pulse rings + mic button
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(AppTheme.Colors.accent.opacity(0.06 - Double(i) * 0.015), lineWidth: 1)
                        .frame(width: CGFloat(140 + i * 44), height: CGFloat(140 + i * 44))
                        .scaleEffect(viewModel.isRecording ? pulseScale + CGFloat(i) * 0.04 : 1.0)
                        .animation(
                            viewModel.isRecording
                                ? .easeInOut(duration: 1.2 + Double(i) * 0.2).repeatForever(autoreverses: true)
                                : .default,
                            value: pulseScale
                        )
                }

                Circle()
                    .fill(AppTheme.Colors.accent.opacity(viewModel.isRecording ? 0.25 : 0.10))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Button(action: { viewModel.toggleRecording() }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Gradients.micButton(recording: viewModel.isRecording))
                            .frame(width: 72, height: 72)
                            .shadow(color: AppTheme.Colors.accent.opacity(0.6), radius: 20, x: 0, y: 8)
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(viewModel.isUploading || viewModel.isProcessing)
            }
            .frame(height: 180)

            // Label below mic
            Text(viewModel.isRecording ? locManager.t("voice.tap_to_stop") : locManager.t("voice.tap_to_record"))
                .font(AppTheme.Typography.label).fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                .tracking(0.3)
        }
    }

    // MARK: - Confirmation

    private var confirmationArea: some View {
        VStack(spacing: AppTheme.Layout.sectionGap) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(viewModel.recordingTime)
                    .font(AppTheme.Typography.mono)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .tracking(2)

                Text(locManager.t("voice.recording_complete"))
                    .font(AppTheme.Typography.label).fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    .tracking(0.5)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Button(action: { viewModel.discardRecording() }) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "trash").font(.system(size: 14, weight: .semibold))
                        Text(locManager.t("voice.discard")).font(AppTheme.Typography.bodyEm)
                    }
                    .foregroundColor(AppTheme.Colors.destructive)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(AppTheme.Colors.destructiveSoft(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius)
                            .stroke(AppTheme.Colors.destructive.opacity(0.25), lineWidth: 1)
                    )
                    .cornerRadius(AppTheme.Layout.cardRadius)
                }

                Button(action: { viewModel.confirmUpload() }) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "paperplane.fill").font(.system(size: 14, weight: .semibold))
                        Text(locManager.t("voice.send")).font(AppTheme.Typography.bodyEm)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        AppTheme.Gradients.accent
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius))
                    )
                    .shadow(color: AppTheme.Colors.accent.opacity(0.35), radius: 14, y: 4)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius)
                .fill(AppTheme.Colors.surfaceElevated(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius)
                .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
        .shadow(color: AppTheme.Colors.accent.opacity(0.12), radius: 16, y: 6)
        .padding(.horizontal, AppTheme.Layout.screenHorizontal)
        .frame(height: 280)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Status Pill

    private var statusArea: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle().fill(statusDotColor).frame(width: 7, height: 7)
                .shadow(color: statusDotColor.opacity(0.8), radius: 4)
            Text(viewModel.isRecording
                 ? "\(locManager.t("voice.status.rec"))  \(viewModel.recordingTime)"
                 : viewModel.statusFallback ?? locManager.t(viewModel.statusKey))
                .font(AppTheme.Typography.label).fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.75))
                .tracking(0.3)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surface(colorScheme).opacity(0.7))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
    }

    // MARK: - On This Day

    private var onThisDaySection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                    Text(locManager.t("home.on_this_day"))
                        .font(AppTheme.Typography.caption).fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.Layout.screenHorizontal)
            .padding(.bottom, AppTheme.Spacing.sm)

            VStack(spacing: 0) {
                ForEach(viewModel.onThisDayEntries) { entry in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        VStack(spacing: 2) {
                            Text("\(entry.yearsAgo)")
                                .font(AppTheme.Typography.heading3)
                                .foregroundColor(AppTheme.Colors.gold)
                            Text(entry.yearsAgo == 1
                                 ? locManager.t("home.year_ago")
                                 : locManager.t("home.years_ago"))
                                .font(AppTheme.Typography.micro)
                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        }
                        .frame(width: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.summary ?? locManager.t("home.past_entry"))
                                .font(AppTheme.Typography.label).fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                                .lineLimit(2)
                            if let mood = entry.moodLabel {
                                Text(mood)
                                    .font(AppTheme.Typography.micro)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    }
                    .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                    .padding(.vertical, AppTheme.Spacing.sm + 2)
                }
            }
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.gold.opacity(0.06), AppTheme.Colors.surfaceElevated(colorScheme)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppTheme.Spacing.radiusLg)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .strokeBorder(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, AppTheme.Layout.screenHorizontal)
            .padding(.bottom, AppTheme.Spacing.md)
        }
    }

    // MARK: - Recent Entries (vertical list)

    private var recentEntriesSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text(locManager.t("voice.recent_entries"))
                    .font(AppTheme.Typography.caption).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                Spacer()
                Button(action: { selectedTab = "journal" }) {
                    Text(locManager.t("voice.view_all"))
                        .font(AppTheme.Typography.label).fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.accent)
                }
            }
            .padding(.horizontal, AppTheme.Layout.screenHorizontal)
            .padding(.bottom, AppTheme.Spacing.sm)

            if viewModel.recentEntries.isEmpty {
                Text(locManager.t("voice.no_entries"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    .padding(.horizontal, AppTheme.Layout.screenHorizontal)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentEntries.prefix(4), id: \.id) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry, selectedTab: $selectedTab)) {
                            RecentEntryRow(entry: entry)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if entry.id != viewModel.recentEntries.prefix(4).last?.id {
                            Divider()
                                .background(AppTheme.Colors.borderSubtle(colorScheme))
                                .padding(.leading, AppTheme.Layout.screenHorizontal + 32)
                        }
                    }
                }
                .background(AppTheme.Colors.surfaceElevated(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusLg)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                    .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
                .padding(.horizontal, AppTheme.Layout.screenHorizontal)
            }
        }
    }

    // MARK: - Helpers

    private var statusDotColor: Color {
        if viewModel.isRecording  { return AppTheme.Colors.destructive }
        if viewModel.statusKey == "voice.status.failed" || viewModel.statusKey == "voice.status.timeout" {
            return AppTheme.Colors.destructive
        }
        if viewModel.isProcessing { return AppTheme.Colors.accent }
        return AppTheme.Colors.success
    }

    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowOpacity = 0.28
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.12
        }
    }

    private func startWaveAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            MainActor.assumeIsolated {
                guard viewModel.isRecording else { timer.invalidate(); return }
                withAnimation(.easeInOut(duration: 0.08)) {
                    waveHeights = waveHeights.map { _ in CGFloat.random(in: 0.1...1.0) }
                }
            }
        }
    }
}

// MARK: - Recent Entry Row

struct RecentEntryRow: View {
    let entry: APIJournalEntry
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(entry.emotionalState.emoji)
                .font(.system(size: 22))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.analysis?.summary ?? entry.transcript ?? locManager.t("voice.processing"))
                    .font(AppTheme.Typography.label).fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    .lineLimit(1)
                Text(entry.relativeDate)
                    .font(AppTheme.Typography.micro)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }

            Spacer()

            if !entry.formattedDuration.isEmpty {
                Text(entry.formattedDuration)
                    .font(AppTheme.Typography.micro).fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenHorizontal)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
    }
}
