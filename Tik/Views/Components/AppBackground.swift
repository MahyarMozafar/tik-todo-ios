import SwiftUI

/// A soft, colorful background in the accent color. The glass cards on top
/// of it pick up its colors.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accent) private var accent
    @AppStorage(PrefKey.colorfulBackground, store: .tik) private var colorful = true

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            if colorful {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [0.55, 0.45], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1],
                    ],
                    colors: [
                        main(0.34), partner(0.20), main(0.12),
                        partner(0.12), main(0), main(0.20),
                        main(0.08), partner(0.22), main(0.28),
                    ]
                )
            }
        }
        .ignoresSafeArea()
    }

    private var strength: Double { colorScheme == .dark ? 0.85 : 1 }

    private func main(_ opacity: Double) -> Color {
        accent.color.opacity(opacity * strength)
    }

    private func partner(_ opacity: Double) -> Color {
        accent.partner.opacity(opacity * strength)
    }
}
