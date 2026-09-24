import SwiftUI

extension View {
    /// Removes the normal list row look, so a glass card can sit right on
    /// the background.
    func cardRow(top: CGFloat = 5, bottom: CGFloat = 5) -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
    }
}

extension View {
    /// Keeps lists at a comfortable reading width on iPad, centered.
    func readableWidth(_ width: CGFloat = 720) -> some View {
        frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
