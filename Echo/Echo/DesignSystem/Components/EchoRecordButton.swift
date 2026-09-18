import SwiftUI
import UIKit

/// Kayıt butonunun durumları (implementation.md §4.17).
nonisolated enum EchoRecordState: Sendable, Equatable {
    case idle
    case recording
    case paused
    case processing
}

/// Kayıt butonu: tek dokunuş toggle, basılı tutma push-to-talk.
/// Kayıt sırasında halkalar ses seviyesine göre nefes alır; işlenirken döner.
struct EchoRecordButton: View {
    let state: EchoRecordState
    /// Anlık ses seviyesi (0–1). Yalnız görsel yoğunluk içindir.
    var level: Double = 0
    var onToggle: () -> Void
    var onPushToTalkChange: ((Bool) -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressing = false

    private var isActive: Bool { state == .recording }

    var body: some View {
        ZStack {
            EchoRippleView(ringCount: 3,
                           intensity: state == .recording ? max(0.25, level) : 0.2,
                           speed: state == .processing ? 1.6 : 1.0,
                           color: AppTheme.color.accent.secondary,
                           isAnimating: state == .recording || state == .processing,
                           lineWidth: 2)
                .frame(width: 132, height: 132)
                .opacity(state == .paused ? 0.5 : 1)

            Circle()
                .fill(AppTheme.gradient.auroraRecord)
                .frame(width: 72, height: 72)
                .overlay {
                    if state == .processing {

                        Circle()
                            .trim(from: 0, to: 0.22)
                            .stroke(AppTheme.color.content.onAccent.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 84, height: 84)
                            .rotationEffect(.degrees(rotation))
                    }
                }

            icon
        }
        .frame(width: 132, height: 132)
        .scaleEffect(isPressing ? 0.96 : 1)
        .animation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion), value: state)
        .animation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion), value: isPressing)
        .contentShape(Circle())
        .onTapGesture {
            impact()
            onToggle()
        }
        .gesture(pushToTalk)
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(isActive ? "record.stop" : "record.start"))
    }

    @ViewBuilder private var icon: some View {
        if isActive {

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.color.content.onAccent)
                .frame(width: 28, height: 28)
        } else {
            Image(systemName: state == .paused ? "play.fill" : "mic.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppTheme.color.content.onAccent)
        }
    }

    /// İşlenirken dönen kısmi ark; Reduce Motion'da sabit kalır.
    private var rotation: Double {
        reduceMotion ? 0 : Date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.4) / 1.4 * 360
    }

    private var pushToTalk: some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .onEnded { _ in

                isPressing = true
                impact()
                onPushToTalkChange?(true)
            }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onEnded { _ in

                isPressing = false
                onPushToTalkChange?(false)
            }
    }

    private func impact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview("Kayıt butonu") {
    VStack(spacing: AppTheme.space.xl) {
        EchoRecordButton(state: .idle, onToggle: {})
        EchoRecordButton(state: .recording, level: 0.7, onToggle: {})
        EchoRecordButton(state: .processing, onToggle: {})
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.color.bg.canvas)
}
