import SwiftUI

/// Asset Catalog'daki semantic renk set'leri (implementation.md §3.2).
/// Light/dark ve `borderSubtle` için yüksek kontrast varyantları Asset Catalog'da tanımlıdır; kodda tema koşulu yazılmaz.
nonisolated enum EchoColorAsset: String, CaseIterable, Sendable {
    case bgCanvas
    case bgSurface
    case bgSurfaceRaised
    case bgSurfaceSunken
    case bgOverlay
    case bgAccentSoft
    case bgAquaSoft
    case bgInverse
    case contentPrimary
    case contentSecondary
    case contentTertiary
    case contentDisabled
    case contentAccent
    case contentOnAccent
    case contentInverse
    case borderSubtle
    case borderDefault
    case borderStrong
    case borderAccent
    case accentPrimary
    case accentPrimaryPressed
    case accentSecondary
    case feedbackSuccess
    case feedbackWarning
    case feedbackDanger
    case feedbackInfo
    case moodHeavy
    case moodLow
    case moodNeutral
    case moodGood
    case moodBright

    var color: Color { Color(rawValue, bundle: .main) }
}

/// Primitive ramp'lar (§3.1). UI'da doğrudan kullanılmaz; yalnız gradient gibi semantic karşılığı olmayan yerlerde.
nonisolated enum EchoPrimitive {
    static let violet50 = Color(hex: 0xF4F0FF)
    static let violet100 = Color(hex: 0xE7DEFF)
    static let violet200 = Color(hex: 0xCDBBFF)
    static let violet300 = Color(hex: 0xB095FF)
    static let violet400 = Color(hex: 0x9270FB)
    static let violet500 = Color(hex: 0x7A52F0)
    static let violet600 = Color(hex: 0x6538D6)
    static let violet700 = Color(hex: 0x5029AC)
    static let violet800 = Color(hex: 0x3B1E80)
    static let violet900 = Color(hex: 0x271455)
    static let violet950 = Color(hex: 0x170B33)

    static let aqua50 = Color(hex: 0xE8FBF7)
    static let aqua100 = Color(hex: 0xC7F5EC)
    static let aqua200 = Color(hex: 0x92EBDB)
    static let aqua300 = Color(hex: 0x57DCC6)
    static let aqua400 = Color(hex: 0x2AC7AE)
    static let aqua500 = Color(hex: 0x14AB94)
    static let aqua600 = Color(hex: 0x0C8A78)
    static let aqua700 = Color(hex: 0x0A6B5E)
    static let aqua800 = Color(hex: 0x085145)
    static let aqua900 = Color(hex: 0x06362E)

    static let amber100 = Color(hex: 0xFFF2D6)
    static let amber300 = Color(hex: 0xFFD27A)
    static let amber500 = Color(hex: 0xF5A524)
    static let amber700 = Color(hex: 0x8F5A08)

    static let coral100 = Color(hex: 0xFFE4E4)
    static let coral300 = Color(hex: 0xFF9F9F)
    static let coral500 = Color(hex: 0xF4606A)
    static let coral700 = Color(hex: 0xC0303C)

    static let neutral0 = Color(hex: 0xFFFFFF)
    static let neutral25 = Color(hex: 0xFBFAFE)
    static let neutral50 = Color(hex: 0xF6F4FB)
    static let neutral100 = Color(hex: 0xEFEDF6)
    static let neutral200 = Color(hex: 0xE2DFEC)
    static let neutral300 = Color(hex: 0xCBC7DA)
    static let neutral400 = Color(hex: 0xA6A1BA)
    static let neutral450 = Color(hex: 0x8C87A3)
    static let neutral500 = Color(hex: 0x736D8A)
    static let neutral600 = Color(hex: 0x5D5873)
    static let neutral700 = Color(hex: 0x443F58)
    static let neutral800 = Color(hex: 0x2E2A40)
    static let neutral850 = Color(hex: 0x241F33)
    static let neutral900 = Color(hex: 0x1A1628)
    static let neutral950 = Color(hex: 0x120F1C)
    static let neutral1000 = Color(hex: 0x0A0812)
}

/// Semantic renk token'ları (§3.2).
nonisolated struct EchoColorPalette: Sendable {
    nonisolated struct Background: Sendable {
        let canvas = EchoColorAsset.bgCanvas.color
        let surface = EchoColorAsset.bgSurface.color
        let surfaceRaised = EchoColorAsset.bgSurfaceRaised.color
        let surfaceSunken = EchoColorAsset.bgSurfaceSunken.color
        let overlay = EchoColorAsset.bgOverlay.color
        let accentSoft = EchoColorAsset.bgAccentSoft.color
        let aquaSoft = EchoColorAsset.bgAquaSoft.color
        let inverse = EchoColorAsset.bgInverse.color
    }

    nonisolated struct Content: Sendable {
        let primary = EchoColorAsset.contentPrimary.color
        let secondary = EchoColorAsset.contentSecondary.color
        let tertiary = EchoColorAsset.contentTertiary.color
        /// WCAG AA altındadır; pasiflik ayrıca ikon veya metinle belirtilmelidir.
        let disabled = EchoColorAsset.contentDisabled.color
        let accent = EchoColorAsset.contentAccent.color
        let onAccent = EchoColorAsset.contentOnAccent.color
        let inverse = EchoColorAsset.contentInverse.color
    }

    nonisolated struct Border: Sendable {
        let subtle = EchoColorAsset.borderSubtle.color
        let `default` = EchoColorAsset.borderDefault.color
        let strong = EchoColorAsset.borderStrong.color
        let accent = EchoColorAsset.borderAccent.color
    }

    nonisolated struct Accent: Sendable {
        let primary = EchoColorAsset.accentPrimary.color
        let primaryPressed = EchoColorAsset.accentPrimaryPressed.color
        let secondary = EchoColorAsset.accentSecondary.color
    }

    nonisolated struct Feedback: Sendable {
        let success = EchoColorAsset.feedbackSuccess.color
        let warning = EchoColorAsset.feedbackWarning.color
        let danger = EchoColorAsset.feedbackDanger.color
        let info = EchoColorAsset.feedbackInfo.color
    }

    /// Mood ölçeği. Renk asla tek başına kullanılmaz; şekil ve etiketle birlikte gösterilir.
    nonisolated struct Mood: Sendable {
        let heavy = EchoColorAsset.moodHeavy.color
        let low = EchoColorAsset.moodLow.color
        let neutral = EchoColorAsset.moodNeutral.color
        let good = EchoColorAsset.moodGood.color
        let bright = EchoColorAsset.moodBright.color
    }

    let bg = Background()
    let content = Content()
    let border = Border()
    let accent = Accent()
    let feedback = Feedback()
    let mood = Mood()
}

/// Gradient'ler (§3.2) yalnız üç yerde kullanılır: kayıt ekranı, streak/başarım kutlaması, paywall.
nonisolated struct EchoGradients: Sendable {
    private static let startAt145 = UnitPoint(x: 0.213, y: 0.090)
    private static let endAt145 = UnitPoint(x: 0.787, y: 0.910)

    var auroraPrimary: LinearGradient {
        LinearGradient(colors: [EchoPrimitive.violet500, EchoPrimitive.violet700, EchoPrimitive.aqua700],
                       startPoint: Self.startAt145, endPoint: Self.endAt145)
    }

    var auroraRecord: EllipticalGradient {
        EllipticalGradient(colors: [EchoPrimitive.violet400, EchoPrimitive.violet900],
                           center: .center, startRadiusFraction: 0, endRadiusFraction: 0.8)
    }

    var auroraCelebration: LinearGradient {
        LinearGradient(colors: [EchoPrimitive.amber500, EchoPrimitive.coral500, EchoPrimitive.violet500],
                       startPoint: Self.startAt145, endPoint: Self.endAt145)
    }
}

nonisolated extension Color {
    /// `0xRRGGBB` biçiminde sRGB renk.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
