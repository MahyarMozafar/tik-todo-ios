import SwiftUI

/// A short burst of confetti from both bottom corners, drawn with Canvas.
/// Change `trigger` to fire a new burst. Nothing happens with Reduce Motion on.
struct ConfettiView: View {
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accent) private var accent
    @State private var burst: Burst?

    private struct Piece {
        var startX: Double
        var velocity: CGVector
        var spin: Double
        var flutter: Double
        var size: CGSize
        var color: Color
        var isRound: Bool
    }

    private struct Burst {
        var start: Date
        var pieces: [Piece]
    }

    private static let duration: TimeInterval = 3.4
    private static let gravity: Double = 620

    var body: some View {
        TimelineView(.animation(paused: burst == nil)) { timeline in
            Canvas { context, size in
                guard let burst else { return }
                let time = timeline.date.timeIntervalSince(burst.start)
                let fade = max(0, min(1, (Self.duration - time) / 0.8))

                for piece in burst.pieces {
                    let x = piece.startX * size.width + piece.velocity.dx * time
                    let y = size.height + 20 + piece.velocity.dy * time + 0.5 * Self.gravity * time * time
                    guard y < size.height + 40 else { continue }

                    var pieceContext = context
                    pieceContext.opacity = fade
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians(piece.spin * time))
                    pieceContext.scaleBy(x: cos(piece.flutter * time * .pi), y: 1)

                    let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2,
                                      width: piece.size.width, height: piece.size.height)
                    let shape = piece.isRound ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
                    pieceContext.fill(shape, with: .color(piece.color))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            fire()
        }
    }

    private func fire() {
        guard !reduceMotion else { return }

        let colors: [Color] = [accent.color, accent.partner, .yellow, .pink, .mint, .orange, .purple]
        var pieces: [Piece] = []
        for side in [0.0, 1.0] {
            let direction = side == 0 ? 1.0 : -1.0
            for _ in 0..<70 {
                let isRound = Double.random(in: 0...1) < 0.3
                let width = Double.random(in: 6...9)
                pieces.append(Piece(
                    startX: side,
                    velocity: CGVector(dx: direction * Double.random(in: 60...380),
                                       dy: -Double.random(in: 820...1180)),
                    spin: Double.random(in: -6...6),
                    flutter: Double.random(in: 1.5...4),
                    size: CGSize(width: width, height: isRound ? width : width * 1.7),
                    color: colors.randomElement()!,
                    isRound: isRound
                ))
            }
        }

        let start = Date.now
        burst = Burst(start: start, pieces: pieces)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.duration))
            if burst?.start == start {
                burst = nil
            }
        }
    }
}
