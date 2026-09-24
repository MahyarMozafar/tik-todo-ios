import SwiftUI

/// A rounded bar that fills from the leading edge in the accent colors.
struct ProgressBar: View {
    var value: Double
    var height: CGFloat = 10

    @Environment(\.accent) private var accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [accent.partner.opacity(0.8), accent.color],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: value > 0 ? max(height, proxy.size.width * value) : 0)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
    }
}
