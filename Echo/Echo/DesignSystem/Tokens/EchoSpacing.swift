import CoreGraphics

/// 4pt grid (implementation.md §3.4).
nonisolated struct EchoSpacingScale: Sendable {
    let xxxxs: CGFloat = 2
    let xxxs: CGFloat = 4
    let xxs: CGFloat = 8
    let xs: CGFloat = 12
    let sm: CGFloat = 16
    let md: CGFloat = 20
    let lg: CGFloat = 24
    let xl: CGFloat = 32
    let xxl: CGFloat = 40
    let xxxl: CGFloat = 48
    let xxxxl: CGFloat = 64
}

/// Layout sabitleri (§3.4).
nonisolated struct EchoLayoutMetrics: Sendable {
    let screenHorizontalPadding: CGFloat = 20
    let sectionGap: CGFloat = 32
    let cardPadding: CGFloat = 16
    let cardPaddingCompact: CGFloat = 12
    let cardPaddingRoomy: CGFloat = 20
    let listRowMinHeight: CGFloat = 56
    let listRowGap: CGFloat = 8
    let tabBarHeight: CGFloat = 56
    let navBarHeightLarge: CGFloat = 96
    let navBarHeightInline: CGFloat = 44
    let minTouchTarget: CGFloat = 44
    /// Günlük gövdesi için yaklaşık 68 karakterlik okunabilir satır genişliği.
    let readableEntryWidth: CGFloat = 620
    let emptyStateMaxWidth: CGFloat = 300
    let onboardingContentMaxWidth: CGFloat = 340
}

/// İkon boyutları (§3.8).
nonisolated struct EchoIconScale: Sendable {
    let sm: CGFloat = 16
    let md: CGFloat = 20
    let lg: CGFloat = 24
    let xl: CGFloat = 32
}
