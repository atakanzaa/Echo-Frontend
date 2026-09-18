import SwiftUI

/// Hareket token'ları (implementation.md §3.7).
/// Reduce Motion açıkken ripple/pulse durur ve geçişler kısa opaklık animasyonuna düşer.
nonisolated struct EchoMotionTokens: Sendable {
    nonisolated struct Durations: Sendable {
        let instant: Double = 0.10
        let fast: Double = 0.18
        let base: Double = 0.26
        let slow: Double = 0.40
        /// Ripple nabzı ve shimmer.
        let ambient: Double = 1.8
    }

    let duration = Durations()

    var snappy: Animation { .spring(response: 0.32, dampingFraction: 0.86) }
    var smooth: Animation { .spring(response: 0.45, dampingFraction: 0.90) }
    /// Başarım ve streak kutlaması.
    var bouncy: Animation { .spring(response: 0.50, dampingFraction: 0.68) }
    var standard: Animation { .easeInOut(duration: duration.base) }
    var enter: Animation { .easeOut(duration: duration.base) }
    var exit: Animation { .easeIn(duration: duration.fast) }

    /// Reduce Motion açıkken hareket yerine kısa opaklık geçişi.
    func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: duration.fast) : animation
    }
}
