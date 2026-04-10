import SwiftUI

struct UserInitialsView: View {
    let displayName: String
    var size: CGFloat = 64

    private var initials: String {
        let parts = displayName
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }

        if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }

        return "EC"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Gradients.accent)
            Text(initials)
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: AppTheme.Colors.accent.opacity(0.35), radius: 12, y: 4)
    }
}
