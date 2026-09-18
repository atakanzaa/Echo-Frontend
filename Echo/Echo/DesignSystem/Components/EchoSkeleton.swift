import SwiftUI

/// Yükleme iskeleti (implementation.md §4.29). Reduce Motion'da sabit yüzey.
struct EchoSkeleton: View {
    var width: CGFloat?
    var height: CGFloat = 16
    var cornerRadius: CGFloat = AppTheme.radius.xs
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppTheme.color.bg.surfaceSunken)
            .frame(width: width, height: height)
            .overlay {
                if !reduceMotion {

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(LinearGradient(colors: [.clear, AppTheme.color.border.subtle.opacity(0.9), .clear],
                                             startPoint: .leading, endPoint: .trailing))
                        .rotationEffect(.degrees(20))
                        .offset(x: phase * 220)
                        .mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
            .clipped()
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: AppTheme.motion.duration.ambient).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

/// Kart yüksekliğinde hazır iskelet.
struct EchoSkeletonCard: View {
    var body: some View {
        EchoCard(style: .flat) {
            VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
                EchoSkeleton(width: 120, height: 12)
                EchoSkeleton(height: 18)
                EchoSkeleton(width: 220, height: 18)
            }
        }
    }
}

#Preview("İskelet") {
    VStack(spacing: AppTheme.space.sm) {
        EchoSkeletonCard()
        EchoSkeletonCard()
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
