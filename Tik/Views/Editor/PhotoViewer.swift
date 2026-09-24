import SwiftUI

/// Shows a task's photo on a black background. Pinch to zoom.
struct PhotoViewer: View {
    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(zoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    MagnifyGesture()
                        .onChanged { zoom = max(1, $0.magnification) }
                        .onEnded { _ in withAnimation(.spring) { zoom = 1 } }
                )
                .accessibilityLabel(Text("Photo"))

            Button(role: .close) {
                dismiss()
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
