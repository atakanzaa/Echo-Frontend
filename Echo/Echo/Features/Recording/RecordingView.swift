import SwiftUI
import Combine
import UIKit

/// Kayıt ekranı (implementation.md §5.4). Tam ekran, tek eylem, ses görünür.
struct RecordingView: View {
    let onFinished: (JournalEntry) -> Void
    let onSwitchToText: () -> Void
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: RecordingViewModel?
    @State private var ticker = Date()
    @State private var pendingSubmissionID: UUID?
    @State private var pendingUsesAudio = false
    @State private var idleTimerWasDisabled = false

    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            EchoAuroraBackground(style: .immersive)
            if let model {

                content(model)
            }
        }
        .onAppear {
            prepare()
            idleTimerWasDisabled = UIApplication.shared.isIdleTimerDisabled
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = idleTimerWasDisabled
        }
        .onReceive(timer) { value in

            ticker = value
            model?.enforceLimit()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active,
                  let model,
                  model.permissionDenied,
                  AudioPermissions.microphone == .granted else { return }
            Task { await model.start() }
        }
    }

    private func prepare() {
        guard model == nil else { return }
        model = RecordingViewModel(limits: environment.remoteConfig.config?.recording,
                                   language: environment.language.language)
    }

    private func content(_ model: RecordingViewModel) -> some View {
        VStack(spacing: AppTheme.space.md) {
            header(model)
            Spacer(minLength: 0)
            if model.permissionDenied {

                permissionContent
            } else if model.phase == .review || model.phase == .submitting {

                ReviewSection(model: model,
                              isLocked: pendingSubmissionID != nil,
                              onSubmit: submit)
            } else {
                recorder(model)
            }
            Spacer(minLength: 0)
            footer(model)
        }
        .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
        .padding(.vertical, AppTheme.space.lg)
    }

    private func header(_ model: RecordingViewModel) -> some View {
        HStack {
            Text(EchoDuration.text(seconds: Int(model.duration)))
                .echoTextStyle(.numeric)
                .monospacedDigit()
                .foregroundStyle(AppTheme.color.content.onAccent)
            if let remaining = model.remainingSeconds, model.phase == .recording {

                Text(verbatim: "· " + EchoDuration.text(seconds: remaining))
                    .echoTextStyle(.subhead)
                    .foregroundStyle(AppTheme.color.content.onAccent.opacity(0.6))
            }
            Spacer()
            EchoIconButton("xmark", accessibilityTitle: "common.close", variant: .glass) {
                close(model)
            }
            .disabled(model.phase == .submitting)
        }
    }

    private var permissionContent: some View {
        EchoGlassSurface {
            EchoEmptyState("record.permissionTitle",
                           message: "record.permissionBody",
                           systemImage: "mic.slash") {
                EchoButton("record.openSettings", variant: .secondary) {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private func recorder(_ model: RecordingViewModel) -> some View {
        VStack(spacing: AppTheme.space.lg) {
            if model.transcriptionUnavailable {

                EchoBanner(kind: .warning,
                           title: String(localized: "record.transcriptionUnavailableTitle"),
                           message: String(localized: "record.transcriptionUnavailableBody"))
            }
            if let error = model.error,
               let message = error.serverMessage ?? error.messageKey.map({ String(localized: String.LocalizationValue($0)) }) {

                EchoBanner(kind: .danger, title: message)
            }
            Text(model.displayedTranscript.isEmpty ? String(localized: "record.prompt") : model.displayedTranscript)
                .echoTextStyle(.entry)
                .foregroundStyle(AppTheme.color.content.onAccent.opacity(0.9))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 120, alignment: .center)
                .lineLimit(2)
                .contentTransition(.opacity)
            EchoWaveform(mode: .live(level: Float(model.level)), height: 72)
                .padding(.horizontal, AppTheme.space.md)
            EchoRecordButton(state: recordState(model), level: model.level) {
                toggle(model)
            }
        }
    }

    private func footer(_ model: RecordingViewModel) -> some View {
        VStack(spacing: AppTheme.space.xs) {
            if model.phase == .recording || model.phase == .paused {

                HStack(spacing: AppTheme.space.sm) {
                    EchoButton(model.phase == .paused ? "record.resume" : "record.pause",
                               variant: .glass, size: .md) {
                        model.phase == .paused ? model.resume() : model.pause()
                    }
                    EchoButton("record.finish", variant: .glass, size: .md) { model.finish() }
                        .disabled(!model.canFinish)
                }
            }
            if model.phase == .idle {

                EchoButton("record.switchToText", variant: .ghost, size: .sm) {
                    model.discard()
                    onSwitchToText()
                }
                .foregroundStyle(AppTheme.color.content.onAccent)
            }
        }
    }

    private func recordState(_ model: RecordingViewModel) -> EchoRecordState {
        switch model.phase {
        case .idle: .idle
        case .recording: .recording
        case .paused: .paused
        case .review, .submitting: .processing
        }
    }

    private func toggle(_ model: RecordingViewModel) {
        switch model.phase {
        case .idle:
            Task { await model.start() }
        case .recording:
            if model.canFinish { model.finish() }
        case .paused:
            model.resume()
        case .review, .submitting:
            break
        }
    }

    private func close(_ model: RecordingViewModel) {
        guard model.phase != .submitting else { return }
        if pendingSubmissionID != nil, pendingUsesAudio {

            model.releaseKeepingAudioFile()
        } else {
            model.discard()
        }
        dismiss()
    }

    /// Transkript varsa metin ucu, yoksa ses ucu kullanılır (rules.md §3, §4).
    private func submit() {
        guard let model else { return }
        model.beginSubmitting()
        Task {
            guard let ownerUserID = environment.session.state.user?.id else {
                model.finishSubmitting(error: .authenticationRequired)
                return
            }
            let submissions = environment.submissions
            let shouldUploadAudio = pendingSubmissionID == nil
                ? model.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                : pendingUsesAudio
            pendingUsesAudio = shouldUploadAudio
            let outcome: JournalSubmissionOutcome
            if shouldUploadAudio, let url = model.audioURL {

                outcome = await submissions.submitAudio(
                    fileURL: url,
                    recordedAt: model.recordedDate,
                    durationSeconds: model.audioDurationSeconds,
                    ownerUserID: ownerUserID,
                    resuming: pendingSubmissionID)
            } else {
                outcome = await submissions.submitTranscript(
                    model.transcript,
                    recordedAt: model.recordedDate,
                    durationSeconds: model.audioDurationSeconds,
                    ownerUserID: ownerUserID,
                    resuming: pendingSubmissionID)
            }
            switch outcome {
            case .accepted(let entry):
                if shouldUploadAudio {
                    // Sunucu işi terminal olana kadar pending store ses dosyasını sahiplenir.
                    model.releaseKeepingAudioFile()
                } else {
                    model.discard()
                }
                onFinished(entry)
                dismiss()
            case .pending(let id, let error):
                pendingSubmissionID = id
                model.finishSubmitting(error: error)
            case .rejected(let error):
                pendingSubmissionID = nil
                pendingUsesAudio = false
                model.finishSubmitting(error: error)
            }
        }
    }
}

/// İnceleme: transkript düzenlenir, kayıt dinlenir, gönderilir (implementation.md §5.5).
private struct ReviewSection: View {
    @Bindable var model: RecordingViewModel
    let isLocked: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.space.sm) {
            if let error = model.error,
               let message = error.serverMessage ?? error.messageKey.map({ String(localized: String.LocalizationValue($0)) }) {

                EchoBanner(kind: .danger, title: message)
            }
            EchoGlassSurface {
                VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                    Text("record.reviewTitle")
                        .echoTextStyle(.headline)
                        .foregroundStyle(AppTheme.color.content.onAccent)
                    EchoTextEditor(placeholder: "record.transcriptPlaceholder",
                                   text: $model.transcript,
                                   characterLimit: model.transcriptLimit,
                                   minHeight: 160,
                                   usesEntryTypography: true)
                        .disabled(isLocked || model.phase == .submitting)
                    if model.player.duration > 0 {

                        VStack(spacing: AppTheme.space.xs) {
                            HStack(spacing: AppTheme.space.xs) {
                                EchoIconButton(model.player.isPlaying ? "pause.fill" : "play.fill",
                                               accessibilityTitle: "record.play", variant: .glass) {
                                    model.player.isPlaying ? model.player.pause() : model.player.play()
                                }
                                EchoWaveform(mode: .player(samples: [], progress: model.player.progress), height: 40) { position in

                                    model.player.seek(to: position)
                                }
                            }
                            EchoSegmentedControl(selection: Binding(
                                get: { model.player.rate },
                                set: { model.player.rate = $0 }
                            ), options: [
                                .init(1, "1×"), .init(1.5, "1.5×"), .init(2, "2×")
                            ])
                        }
                    }
                }
            }
            EchoButton(isLocked ? "common.retry" : "record.saveAndReflect",
                       variant: .primary, size: .lg, fullWidth: true,
                       isLoading: model.phase == .submitting, action: onSubmit)
        }
    }
}
