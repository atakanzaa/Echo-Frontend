import SwiftUI

/// Koç sohbeti balonu (implementation.md §4.20).
nonisolated enum EchoChatRole: Sendable {
    case user
    case coach
    case system
}

struct EchoChatBubble: View {
    let role: EchoChatRole
    let text: String
    /// Yanıt akarken kelime kelime belirir; sunucu SSE göndermediği için yalnız görsel yumuşatmadır.
    var isStreaming: Bool = false
    var onCopy: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedWords = 0

    private var words: [String] { text.split(separator: " ").map(String.init) }

    var body: some View {
        HStack {
            if role == .user { Spacer(minLength: 40) }
            content
            if role == .coach { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    @ViewBuilder private var content: some View {
        switch role {
        case .system:
            Text(text)
                .echoTextStyle(.footnote)
                .foregroundStyle(AppTheme.color.content.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        case .user, .coach:
            bubble
        }
    }

    private var bubble: some View {
        Text(displayText)
            .echoTextStyle(.body)
            .foregroundStyle(role == .user ? AppTheme.color.content.onAccent : AppTheme.color.content.primary)
            .padding(.horizontal, AppTheme.space.xs)
            .padding(.vertical, AppTheme.space.xxs + 2)
            .background {
                if role == .user {

                    bubbleShape.fill(AppTheme.color.accent.primary)
                } else {
                    bubbleShape.fill(AppTheme.color.bg.surface)
                        .overlay { bubbleShape.strokeBorder(AppTheme.color.border.subtle, lineWidth: 1) }
                }
            }
            .contextMenu {
                if let onCopy {

                    Button("common.copy", systemImage: "doc.on.doc", action: onCopy)
                }
            }
            .onAppear { startStreamingIfNeeded() }
            .onChange(of: text) { _, _ in startStreamingIfNeeded() }
    }

    private var displayText: String {
        guard isStreaming, !reduceMotion, revealedWords < words.count else { return text }
        return words.prefix(max(revealedWords, 1)).joined(separator: " ")
    }

    private var bubbleShape: UnevenRoundedRectangle {
        let large = AppTheme.radius.lg
        let small = AppTheme.radius.xs
        return UnevenRoundedRectangle(
            topLeadingRadius: large,
            bottomLeadingRadius: role == .coach ? small : large,
            bottomTrailingRadius: role == .user ? small : large,
            topTrailingRadius: large,
            style: .continuous)
    }

    private var alignment: Alignment {
        switch role {
        case .user: .trailing
        case .coach: .leading
        case .system: .center
        }
    }

    private func startStreamingIfNeeded() {
        guard isStreaming, !reduceMotion else { return }
        revealedWords = 0
        Task { @MainActor in
            for index in words.indices {

                try? await Task.sleep(for: .milliseconds(45))
                withAnimation(.easeOut(duration: AppTheme.motion.duration.fast)) {
                    revealedWords = index + 1
                }
            }
        }
    }
}

#Preview("Sohbet balonu") {
    VStack(spacing: AppTheme.space.xs) {
        EchoChatBubble(role: .coach, text: "Bugün seni en çok ne yordu?")
        EchoChatBubble(role: .user, text: "Sabah toplantısı uzayınca yürüyüşe çıkamadım.")
        EchoChatBubble(role: .system, text: "Oturum kapatıldı")
        EchoTypingIndicator()
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
