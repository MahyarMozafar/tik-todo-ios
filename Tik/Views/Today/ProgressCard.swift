import SwiftUI

/// "3 of 5 done" with a bar that fills up as tasks are ticked.
struct ProgressCard: View {
    let done: Int
    let total: Int

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                if done == total {
                    Label("All done for today!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.tint)
                } else {
                    Text("\(done) of \(total) done")
                }
                Spacer()
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: fraction))
            }
            .tikFont(.subheadline, weight: .semibold)

            ProgressBar(value: fraction)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .animation(.snappy, value: done)
        .accessibilityElement(children: .combine)
    }
}
