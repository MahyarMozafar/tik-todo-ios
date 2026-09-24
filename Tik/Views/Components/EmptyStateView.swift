import SwiftUI

/// A big glass icon with a title and a short message, for empty screens.
struct EmptyStateView: View {
    let symbol: String
    let title: Text
    let message: Text

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 88, height: 88)
                .glassEffect(.regular, in: .circle)

            title
                .tikFont(.title3, weight: .semibold)
                .multilineTextAlignment(.center)

            message
                .tikFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 56)
        .accessibilityElement(children: .combine)
    }
}
