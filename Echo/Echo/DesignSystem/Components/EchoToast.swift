import SwiftUI

/// Geçici bildirim (implementation.md §4.12). Metin çağıran taraftan gelir; sunucu metni olduğu gibi gösterilir.
nonisolated struct EchoToastMessage: Identifiable, Equatable, Sendable {
    let id = UUID()
    let text: String
    var systemImage: String?
    var undoTitle: String?

    init(_ text: String, systemImage: String? = nil, undoTitle: String? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.undoTitle = undoTitle
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

struct EchoToastView: View {
    let message: EchoToastMessage
    var onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.space.xxs) {
            if let systemImage = message.systemImage {

                Image(systemName: systemImage).font(.system(size: AppTheme.icon.sm, weight: .semibold))
            }
            Text(message.text).echoTextStyle(.subhead)
            if let undoTitle = message.undoTitle, let onUndo {

                Button(undoTitle, action: onUndo)
                    .echoTextStyle(.subhead)
                    .foregroundStyle(AppTheme.color.accent.secondary)
                    .padding(.leading, AppTheme.space.xxxs)
            }
        }
        .foregroundStyle(AppTheme.color.content.inverse)
        .padding(.horizontal, AppTheme.space.sm)
        .padding(.vertical, AppTheme.space.xs)
        .background(Capsule().fill(AppTheme.color.bg.inverse))
        .shadow(color: EchoPrimitive.neutral950.opacity(0.18), radius: 12, y: 6)
    }
}

/// Toast kuyruğu: aynı anda tek mesaj gösterilir, 2.5 saniye sonra kaybolur.
@Observable
final class EchoToastCenter {
    private(set) var current: EchoToastMessage?
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    func show(_ message: EchoToastMessage) {
        current = message
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.current = nil }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}

private struct EchoToastHost: ViewModifier {
    let center: EchoToastCenter
    var onUndo: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = center.current {

                EchoToastView(message: message, onUndo: onUndo)
                    .padding(.bottom, AppTheme.space.xl)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .gesture(DragGesture(minimumDistance: 20).onEnded { _ in center.dismiss() })
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(AppTheme.motion.resolved(AppTheme.motion.smooth, reduceMotion: reduceMotion), value: center.current)
    }
}

extension View {
    /// Ekranın altına toast katmanı ekler.
    func echoToasts(_ center: EchoToastCenter, onUndo: (() -> Void)? = nil) -> some View {
        modifier(EchoToastHost(center: center, onUndo: onUndo))
    }
}

#Preview("Toast") {
    EchoToastView(message: EchoToastMessage("Kayıt silindi", systemImage: "trash", undoTitle: "Geri al"), onUndo: {})
        .padding()
        .background(AppTheme.color.bg.canvas)
}
