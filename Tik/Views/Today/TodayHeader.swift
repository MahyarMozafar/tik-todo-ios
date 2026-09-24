import SwiftUI

/// "Thursday, Mehr 2" above a big "Today", with the Settings button.
struct TodayHeader: View {
    let date: Date
    var onOpenSettings: () -> Void

    @Environment(\.dateFormatting) private var formatting
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(formatting.fullDay(date))
                    .tikFont(.subheadline, weight: .semibold)
                    .textCase(language == .english ? .uppercase : nil)
                    .tracking(language == .english ? 0.6 : 0)
                    .foregroundStyle(.tint)

                Text("Today")
                    .tikFont(.largeTitle, weight: .bold, design: .rounded)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .accessibilityLabel(Text("Settings"))
            .accessibilityIdentifier("settingsButton")
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}
