import SwiftUI

/// The round check box. When ticked it fills with the accent color, draws
/// a check mark, and gives a small bounce.
struct CheckCircle: View {
    var isDone: Bool
    var ringColor: Color = .secondary
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(ringColor.opacity(isDone ? 0 : 0.75), lineWidth: 1.8)

            Circle()
                .fill(.tint)
                .scaleEffect(isDone ? 1 : 0.2)
                .opacity(isDone ? 1 : 0)

            CheckmarkShape()
                .trim(from: 0, to: isDone ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.46, height: size * 0.34)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: isDone)
        .keyframeAnimator(initialValue: 1.0, trigger: isDone) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(1.18, duration: 0.14)
                SpringKeyframe(1.0, duration: 0.3)
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
