import SwiftUI
import Combine

struct JournalDetailView: View {
    let entry: APIJournalEntry
    @Binding var selectedTab: String
    @State private var showTranscript = false
    @State private var navigateToCoach = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: — Header
                    headerSection

                    // MARK: — AI Summary
                    if let summary = entry.analysis?.summary, !summary.isEmpty {
                        sectionCard(title: "AI Summary", icon: "sparkles") {
                            Text(summary)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                                .lineSpacing(3)
                        }
                    }

                    // MARK: — Key Emotions
                    if let emotions = entry.analysis?.keyEmotions, !emotions.isEmpty {
                        sectionCard(title: "Duygular", icon: "heart.text.square") {
                            FlowLayout(spacing: 8) {
                                ForEach(emotions, id: \.self) { emotion in
                                    Text(emotion)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(emotionColor(emotion).opacity(0.3))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(emotionColor(emotion).opacity(0.5), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // MARK: — Topics
                    if let topics = entry.analysis?.topics, !topics.isEmpty {
                        sectionCard(title: "Konular", icon: "tag") {
                            FlowLayout(spacing: 8) {
                                ForEach(topics, id: \.self) { topic in
                                    HStack(spacing: 4) {
                                        Image(systemName: "number")
                                            .font(.system(size: 10))
                                        Text(topic)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.12))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // MARK: — Energy Level
                    if let energy = entry.analysis?.energyLevel, !energy.isEmpty {
                        sectionCard(title: "Enerji Seviyesi", icon: "bolt.fill") {
                            HStack(spacing: 12) {
                                energyIndicator(level: energy)
                                Text(energy.capitalized)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // MARK: — Reflective Question
                    if let question = entry.analysis?.reflectiveQuestion, !question.isEmpty {
                        sectionCard(title: "Yansıma Sorusu", icon: "questionmark.bubble") {
                            Text(question)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                                .lineSpacing(3)
                                .italic()
                        }
                    }

                    // MARK: — Transcript (genisletilebilir)
                    if let transcript = entry.transcript, !transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { withAnimation { showTranscript.toggle() } }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    Text("Transkript")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    Spacer()
                                    Image(systemName: showTranscript ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                }
                            }
                            if showTranscript {
                                Text(transcript)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                                    .lineSpacing(4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(16)
                        .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }

                    // MARK: — Coach ile Konuş butonu
                    Button(action: {
                        CoachJournalContext.shared.pendingJournalEntryId = entry.id
                        selectedTab = "coach"
                        dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16))
                            Text("Coach ile Konuş")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.498, green: 0.075, blue: 0.929),
                                    Color(red: 0.596, green: 0.283, blue: 0.941)
                                ]),
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Journal Detay")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: — Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    if !entry.formattedDuration.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                                .font(.system(size: 12))
                            Text(entry.formattedDuration)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    }
                }
                Spacer()
                // Mood badge
                if let analysis = entry.analysis {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(entry.emotionalState.color)
                            .frame(width: 12, height: 12)
                        Text((analysis.moodLabel ?? "neutral").capitalized)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(entry.emotionalState.color)
                        if let score = analysis.moodScore {
                            Text(String(format: "%.0f/10", score * 10))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(entry.emotionalState.color.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    // MARK: — Helpers

    private var formattedDate: String {
        guard let date = ISO8601DateFormatter().date(from: entry.recordedAt) else { return entry.entryDate }
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy, EEEE"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            content()
        }
        .padding(16)
        .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private func emotionColor(_ emotion: String) -> Color {
        let lower = emotion.lowercased()
        if lower.contains("stres") || lower.contains("kayg") || lower.contains("anger") || lower.contains("fear") {
            return Color(red: 0.937, green: 0.267, blue: 0.267)
        } else if lower.contains("mutlu") || lower.contains("huzur") || lower.contains("calm") || lower.contains("joy") {
            return Color(red: 0.235, green: 0.808, blue: 0.996)
        } else if lower.contains("motiv") || lower.contains("enerj") || lower.contains("heyecan") {
            return Color(red: 0.133, green: 0.769, blue: 0.368)
        } else {
            return Color(red: 0.659, green: 0.333, blue: 0.929)
        }
    }

    @ViewBuilder
    private func energyIndicator(level: String) -> some View {
        let count = level.lowercased() == "high" ? 3 : level.lowercased() == "medium" ? 2 : 1
        let color = level.lowercased() == "high" ? Color(red: 0.133, green: 0.769, blue: 0.368) :
                    level.lowercased() == "medium" ? Color(red: 0.996, green: 0.757, blue: 0.027) :
                    Color(red: 0.937, green: 0.267, blue: 0.267)
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < count ? color : Color.white.opacity(0.1))
                    .frame(width: 20, height: 8 + CGFloat(i) * 4)
            }
        }
    }
}

// MARK: — FlowLayout (yatay chip dizilimi)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
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
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: — Coach Journal Context (singleton — journal'dan coach'a veri aktarimi)

final class CoachJournalContext: ObservableObject {
    static let shared = CoachJournalContext()
    @Published var pendingJournalEntryId: String?
    private init() {}
}
