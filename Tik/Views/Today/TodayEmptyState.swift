import SwiftUI

/// What Today shows when there is nothing left to see.
struct TodayEmptyState: View {
    /// True when there were tasks today and they are all done (and done
    /// tasks are hidden).
    var allDone: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: allDone ? "checkmark.seal.fill" : "sun.max.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 96, height: 96)
                .glassEffect(.regular, in: .circle)

            Text(allDone ? LocalizedStringKey("Everything is done") : "A fresh day")
                .tikFont(.title3, weight: .semibold)

            Text(allDone ? LocalizedStringKey("Enjoy the rest of your day.") : "Tap + to add your first task.")
                .tikFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}
