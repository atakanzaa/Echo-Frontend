import SwiftUI
import Combine

struct JournalDetailView: View {
    let entry: APIJournalEntry
    @Binding var selectedTab: String
    @EnvironmentObject var locManager: LocalizationManager
    @StateObject private var goalViewModel = GoalViewModel()
    @State private var showTranscript = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    headerSection

                    if let message = goalViewModel.successMessage {
                        InlineBannerView(message: message, type: .info) {
                            goalViewModel.successMessage = nil
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    if let message = goalViewModel.errorMessage {
                        InlineBannerView(message: message, type: .error) {
                            goalViewModel.errorMessage = nil
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    if isAnalysisProcessing {
                        analysisProcessingCard
                    }

                    if let summary = entry.analysis?.summary, !summary.isEmpty {
                        aiSynthesisCard(summary: summary)
                    }

                    if !goalViewModel.journalSuggestions.isEmpty {
                        goalSuggestionsSection
                    }

                    if let emotions = entry.analysis?.keyEmotions, !emotions.isEmpty {
                        keyEmotionsSection(emotions: emotions)
                    }

                    if let energy = entry.analysis?.energyLevel, !energy.isEmpty {
                        energySection(level: energy)
                    }

                    if let question = entry.analysis?.reflectiveQuestion, !question.isEmpty {
                        reflectionCard(question: question)
                    }

                    if let transcript = entry.transcript, !transcript.isEmpty {
                        transcriptSection(transcript)
                    }

                    coachButton
                        .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
                }
                .padding(.top, AppTheme.Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(formattedDate)
                    .font(AppTheme.Typography.heading3)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
        }
        .onAppear {
            if entry.analysis != nil {
                goalViewModel.loadJournalSuggestions(entryId: entry.id)
            }
        }
        .onDisappear {
            goalViewModel.cancelAll()
        }
    }

    private var goalSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                Text(locManager.t("goal.suggestions.title"))
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            ForEach(goalViewModel.journalSuggestions) { suggestion in
                GoalSuggestionCardView(
                    suggestion: suggestion,
                    isLoading: goalViewModel.isInFlight(goalId: suggestion.id),
                    onPrimary: { goalViewModel.acceptSuggestion(suggestion) },
                    onSecondary: { goalViewModel.rejectSuggestion(suggestion) }
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if !entry.formattedDuration.isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "waveform").font(.system(size: 11))
                            Text(entry.formattedDuration.uppercased()).font(AppTheme.Typography.label).fontWeight(.semibold)
                        }
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 4)
                        .background(AppTheme.Colors.accentSoft(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusFull)
                    }

                    if let analysis = entry.analysis {
                        HStack(spacing: 5) {
                            Circle().fill(entry.emotionalState.color).frame(width: 7, height: 7)
                            Text(locManager.t(analysis.moodLocalizationKey))
                                .font(AppTheme.Typography.label).fontWeight(.semibold)
                                .foregroundColor(entry.emotionalState.color)
                            if let score = analysis.moodScore {
                                Text("· \(Int(score * 100))%")
                                    .font(AppTheme.Typography.label)
                                    .foregroundColor(entry.emotionalState.color.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 4)
                        .background(entry.emotionalState.color.opacity(0.12))
                        .cornerRadius(AppTheme.Spacing.radiusFull)
                    }
                }
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
            .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func aiSynthesisCard(summary: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.Gradients.accent)
                Text(locManager.t("journal.ai_synthesis"))
                    .font(AppTheme.Typography.caption).fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Text(summary)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.accentSoft(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
            .strokeBorder(AppTheme.Colors.accent.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var analysisProcessingCard: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.sm) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                .scaleEffect(0.9)
            Text(locManager.t("journal.analysis_processing"))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
                .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func keyEmotionsSection(emotions: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel(icon: "heart.text.square", title: locManager.t("journal.key_emotions"))
            FlowLayout(spacing: AppTheme.Spacing.sm) {
                ForEach(emotions, id: \.self) { emotion in
                    Text(emotion)
                        .font(AppTheme.Typography.caption).fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, AppTheme.Spacing.xs + 2)
                        .background(AppTheme.Colors.surface(colorScheme))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                            .stroke(emotionColor(emotion).opacity(0.4), lineWidth: 1))
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.6))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func energySection(level: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel(icon: "bolt.fill", title: locManager.t("journal.energy_state"))
            HStack(spacing: AppTheme.Spacing.md) {
                energyBar(level: level)
                Text(level.capitalized)
                    .font(AppTheme.Typography.caption).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.6))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func reflectionCard(question: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel(icon: "questionmark.bubble", title: locManager.t("journal.reflection"))
            Text(question)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                .lineSpacing(3).italic()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusLg)
            .strokeBorder(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1))
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func transcriptSection(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showTranscript.toggle() } }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "doc.text").font(.system(size: 14)).foregroundColor(AppTheme.Colors.accent)
                    Text(locManager.t("journal.transcript"))
                        .font(AppTheme.Typography.caption).fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    Spacer()
                    Image(systemName: showTranscript ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12)).foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
            }
            if showTranscript {
                Text(transcript)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary(colorScheme))
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme).opacity(0.6))
        .cornerRadius(AppTheme.Spacing.radiusLg)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var coachButton: some View {
        Button(action: {
            CoachJournalContext.shared.pendingJournalEntryId = entry.id
            selectedTab = "coach"
            dismiss()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 16))
                Text(locManager.t("journal.talk_ai_coach")).font(AppTheme.Typography.bodyEm)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Gradients.accent)
            .cornerRadius(AppTheme.Spacing.radiusLg)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func sectionLabel(icon: String, title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(AppTheme.Colors.accent)
            Text(title).font(AppTheme.Typography.caption).fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
    }

    private var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: entry.recordedAt) else { return entry.entryDate }
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"
        return f.string(from: date)
    }

    private func emotionColor(_ emotion: String) -> Color {
        let l = emotion.lowercased()
        if l.contains("stress") || l.contains("anger") || l.contains("fear") { return AppTheme.Colors.destructive }
        if l.contains("calm") || l.contains("joy") || l.contains("happy") { return AppTheme.Colors.moodVeryPositive }
        if l.contains("motiv") || l.contains("energy") { return AppTheme.Colors.success }
        return AppTheme.Colors.accent
    }

    private var isAnalysisProcessing: Bool {
        guard entry.analysis == nil else { return false }
        let normalized = entry.status.lowercased()
        let terminal = ["complete", "completed", "done", "success", "failed", "error"]
        return !terminal.contains(normalized)
    }

    @ViewBuilder
    private func energyBar(level: String) -> some View {
        let count = level.lowercased() == "high" ? 3 : level.lowercased() == "medium" ? 2 : 1
        let color: Color = level.lowercased() == "high" ? AppTheme.Colors.success :
                           level.lowercased() == "medium" ? AppTheme.Colors.warning : AppTheme.Colors.destructive
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < count ? color : Color.white.opacity(0.1))
                    .frame(width: 20, height: 8 + CGFloat(i) * 4)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0; var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height); x += size.width + spacing; maxX = max(maxX, x)
        }
        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

final class CoachJournalContext: ObservableObject {
    static let shared = CoachJournalContext()
    @Published var pendingJournalEntryId: String?
    private init() {}
}
