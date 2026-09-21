import SwiftUI

/// Yazılı kayıt (implementation.md §5.5). Süre gönderilmez; karakter sınırı sunucudan gelir.
struct ComposerView: View {
    let onFinished: (JournalEntry) -> Void
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var recordedAt = Date()
    @State private var isWorking = false
    @State private var error: AppError?
    @State private var pendingSubmissionID: UUID?
    @FocusState private var isFocused: Bool

    private var limit: Int? { environment.remoteConfig.config?.recording.maxTranscriptCharacters }

    var body: some View {
        ZStack {
            AppTheme.color.bg.canvas.ignoresSafeArea()
            VStack(spacing: AppTheme.space.sm) {
                if let error, let message = error.serverMessage ?? error.messageKey.map({ String(localized: String.LocalizationValue($0)) }) {

                    EchoBanner(kind: .danger, title: message)
                }
                EchoTextEditor(placeholder: "composer.placeholder", text: $text,
                               characterLimit: limit, minHeight: 240, usesEntryTypography: true)
                    .focused($isFocused)
                    // Belirsiz sonuçtan sonra aynı idempotency anahtarı ve aynı gövde korunur.
                    .disabled(pendingSubmissionID != nil)
                EchoButton("common.save", size: .lg, fullWidth: true, isLoading: isWorking) { submit() }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || exceedsLimit)
                Spacer(minLength: 0)
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
        }
        .navigationTitle(Text("composer.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFocused = true }
    }

    private var exceedsLimit: Bool {
        guard let limit else { return false }
        return text.count > limit
    }

    /// Yazılı girişte süre gönderilmez; kayıt anı cihaz saatinden alınır, günü sunucu sabitler.
    private func submit() {
        isWorking = true
        error = nil
        Task {
            guard let ownerUserID = environment.session.state.user?.id else {
                error = .authenticationRequired
                isWorking = false
                return
            }
            let outcome = await environment.submissions.submitTranscript(
                text,
                recordedAt: recordedAt,
                durationSeconds: nil,
                ownerUserID: ownerUserID,
                resuming: pendingSubmissionID)
            switch outcome {
            case .accepted(let entry):
                onFinished(entry)
                dismiss()
            case .pending(let id, let submissionError):
                pendingSubmissionID = id
                error = submissionError
            case .rejected(let submissionError):
                pendingSubmissionID = nil
                error = submissionError
            }
            isWorking = false
        }
    }
}
