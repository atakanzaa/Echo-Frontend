import SwiftUI

struct NotificationBadge: View {
    let count: Int

    var body: some View {
        Group {
            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
    }
}
