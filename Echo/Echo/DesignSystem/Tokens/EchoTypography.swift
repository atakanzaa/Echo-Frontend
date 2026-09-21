import SwiftUI

/// Tipografi token'ları (implementation.md §3.3). Hepsi Dynamic Type ile ölçeklenir.
/// Günlük gövdesi serif (`entry`, `entryQuote`), arayüz sans.
nonisolated enum EchoTextStyle: CaseIterable, Sendable {
    case display
    case title1
    case title2
    case title3
    case headline
    case body
    case bodyEmphasis
    case entry
    case entryQuote
    case callout
    case subhead
    case footnote
    case caption
    case caption2
    case numeric
    /// Bölüm başlığı ("Son 7 gün", "Bugün için hedeflerin").
    case sectionTitle
    /// Günün sorusu; serif, sayfanın tek büyük metni.
    case question

    var size: CGFloat {
        switch self {
        case .display: 34
        case .title1: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body, .bodyEmphasis, .entryQuote: 17
        case .entry: 18
        case .callout: 16
        case .subhead: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        case .numeric: 28
        case .sectionTitle: 21
        case .question: 32
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .display: 40
        case .title1: 34
        case .title2: 28
        case .title3: 25
        case .headline: 22
        case .body, .bodyEmphasis: 24
        case .entry: 28
        case .entryQuote: 26
        case .callout: 21
        case .subhead: 20
        case .footnote: 18
        case .caption: 16
        case .caption2: 13
        case .numeric: 32
        case .sectionTitle: 26
        case .question: 38
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .title1, .numeric, .sectionTitle: .bold
        case .title2, .title3, .headline, .bodyEmphasis, .caption2: .semibold
        case .subhead, .caption: .medium
        case .body, .entry, .entryQuote, .callout, .footnote, .question: .regular
        }
    }

    var design: Font.Design {
        switch self {
        case .display, .title1, .sectionTitle: .rounded
        case .entry, .entryQuote, .question: .serif
        default: .default
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display: -0.4
        case .title1: -0.3
        case .title2, .numeric, .question: -0.2
        case .sectionTitle: -0.15
        case .title3: -0.1
        case .caption: 0.2
        case .caption2: 0.4
        default: 0
        }
    }

    /// Dynamic Type ölçeklemesinin bağlandığı sistem stili.
    var relativeTo: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title1, .numeric, .question: .title
        case .title2: .title2
        case .title3, .sectionTitle: .title3
        case .headline: .headline
        case .body, .bodyEmphasis, .entry, .entryQuote: .body
        case .callout: .callout
        case .subhead: .subheadline
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        }
    }

    var isItalic: Bool { self == .entryQuote }
    var usesMonospacedDigits: Bool { self == .numeric }

    /// Satır yüksekliğini yaklaşık korumak için fontun doğal satır aralığına eklenecek boşluk.
    var lineSpacing: CGFloat { max(0, lineHeight - size * 1.2) }

    func font(size scaledSize: CGFloat) -> Font {
        var font = Font.system(size: scaledSize, weight: weight, design: design)
        if isItalic { font = font.italic() }
        if usesMonospacedDigits { font = font.monospacedDigit() }
        return font
    }
}

/// `AppTheme.type.entry` gibi facade erişimi için tipografi ölçeği.
nonisolated struct EchoTypeScale: Sendable {
    let display = EchoTextStyle.display
    let title1 = EchoTextStyle.title1
    let title2 = EchoTextStyle.title2
    let title3 = EchoTextStyle.title3
    let headline = EchoTextStyle.headline
    let body = EchoTextStyle.body
    let bodyEmphasis = EchoTextStyle.bodyEmphasis
    let entry = EchoTextStyle.entry
    let entryQuote = EchoTextStyle.entryQuote
    let callout = EchoTextStyle.callout
    let subhead = EchoTextStyle.subhead
    let footnote = EchoTextStyle.footnote
    let caption = EchoTextStyle.caption
    let caption2 = EchoTextStyle.caption2
    let numeric = EchoTextStyle.numeric
    let sectionTitle = EchoTextStyle.sectionTitle
    let question = EchoTextStyle.question
}

private struct EchoTextStyleModifier: ViewModifier {
    private let style: EchoTextStyle
    @ScaledMetric private var size: CGFloat
    @ScaledMetric private var lineSpacing: CGFloat

    init(_ style: EchoTextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
        _lineSpacing = ScaledMetric(wrappedValue: style.lineSpacing, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(style.font(size: size))
            .lineSpacing(lineSpacing)
            .tracking(style.tracking)
    }
}

extension View {
    /// Tipografi token'ını font, satır aralığı ve harf aralığıyla birlikte uygular.
    func echoTextStyle(_ style: EchoTextStyle) -> some View {
        modifier(EchoTextStyleModifier(style))
    }
}
