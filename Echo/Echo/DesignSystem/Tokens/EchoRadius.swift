import SwiftUI

/// Köşe yarıçapları (implementation.md §3.5). Tüm köşeler `.continuous`.
nonisolated struct EchoRadiusScale: Sendable {
    let xs: CGFloat = 6
    let sm: CGFloat = 10
    let md: CGFloat = 14
    let lg: CGFloat = 20
    let xl: CGFloat = 28
    let full: CGFloat = 999

    /// İç içe kutularda köşeler paralel kalsın diye iç yarıçap: `max(xs, outer - padding)`.
    func nested(outer: CGFloat, padding: CGFloat) -> CGFloat {
        max(xs, outer - padding)
    }
}

extension Shape where Self == RoundedRectangle {
    /// `.continuous` köşeli dikdörtgen.
    static func echoRounded(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
