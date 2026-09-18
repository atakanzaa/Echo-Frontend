import SwiftUI

/// Avatar (implementation.md §4.13). Görsel yoksa isimden türetilen baş harfler ve tint kullanılır.
nonisolated enum EchoAvatarSize: CGFloat, Sendable {
    case xs = 24
    case sm = 32
    case md = 40
    case lg = 56
    case xl = 88
}

struct EchoAvatar: View {
    private let name: String?
    private let size: EchoAvatarSize
    private let hasStreakRing: Bool

    init(name: String?, size: EchoAvatarSize = .md, hasStreakRing: Bool = false) {
        self.name = name
        self.size = size
        self.hasStreakRing = hasStreakRing
    }

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.18))
            Text(initials)
                .echoTextStyle(size.rawValue >= EchoAvatarSize.lg.rawValue ? .title3 : .subhead)
                .foregroundStyle(tint)
        }
        .frame(width: size.rawValue, height: size.rawValue)
        .overlay {
            if hasStreakRing {

                Circle().strokeBorder(EchoPrimitive.amber500, lineWidth: 2)
            }
        }
        .accessibilityHidden(true)
    }

    private var initials: String {
        guard let name, !name.isEmpty else { return "•" }
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "•" : letters.uppercased()
    }

    /// İsimden kararlı bir tint; rastgele değil, aynı isim hep aynı rengi alır.
    private var tint: Color {
        guard let name, !name.isEmpty else { return AppTheme.color.content.tertiary }
        let hash = name.unicodeScalars.reduce(into: UInt32(7)) { partial, scalar in
            partial = partial &* 31 &+ scalar.value
        }
        return hash % 2 == 0 ? AppTheme.color.accent.primary : AppTheme.color.accent.secondary
    }
}

#Preview("Avatar") {
    HStack(spacing: AppTheme.space.sm) {
        EchoAvatar(name: "Atakan Yel", size: .lg, hasStreakRing: true)
        EchoAvatar(name: "Echo üyesi")
        EchoAvatar(name: nil, size: .sm)
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
