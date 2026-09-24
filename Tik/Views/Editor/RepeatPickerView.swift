import SwiftUI

/// Picks how a task repeats: every day, on certain weekdays, every few
/// days, and so on.
struct RepeatPickerView: View {
    @Binding var rule: RepeatRule?
    /// The task's day, used as the first weekday when "On Certain Days" is picked.
    var day: Date

    @Environment(\.dateFormatting) private var formatting

    private enum Choice: Hashable {
        case never, daily, weekly, monthly, yearly, weekdays, everyNDays
    }

    var body: some View {
        Form {
            Section {
                option("Never", .never)
                option("Every Day", .daily)
                option("Every Week", .weekly)
                option("Every Month", .monthly)
                option("Every Year", .yearly)
            }

            Section {
                option("On Certain Days", .weekdays)
                if current == .weekdays {
                    weekdayPicker
                }

                option("Every Few Days", .everyNDays)
                if current == .everyNDays, let interval = rule?.interval {
                    Stepper(value: intervalBinding, in: 2...30) {
                        Text("Every \(interval) days")
                    }
                }
            } footer: {
                Text("When you tick a repeating task, the next one is added for you.")
            }
        }
        .navigationTitle(Text("Repeat"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var current: Choice {
        switch rule?.frequency {
        case nil: .never
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        case .weekdays: .weekdays
        case .everyNDays: .everyNDays
        }
    }

    private func option(_ title: LocalizedStringKey, _ choice: Choice) -> some View {
        Button {
            select(choice)
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(Color.primary)
                Spacer()
                if current == choice {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
        }
        .accessibilityAddTraits(current == choice ? .isSelected : [])
    }

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(formatting.orderedWeekdays, id: \.number) { weekday in
                let isOn = rule?.weekdays.contains(weekday.number) ?? false
                Button {
                    toggleWeekday(weekday.number)
                } label: {
                    Text(weekday.letter)
                        .tikFont(.subheadline, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .foregroundStyle(isOn ? Color.white : Color.primary)
                        .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(weekday.shortName))
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private var intervalBinding: Binding<Int> {
        Binding(
            get: { rule?.interval ?? 2 },
            set: { rule?.interval = $0 }
        )
    }

    private func select(_ choice: Choice) {
        withAnimation(.snappy) {
            switch choice {
            case .never:
                rule = nil
            case .daily:
                rule = RepeatRule(frequency: .daily)
            case .weekly:
                rule = RepeatRule(frequency: .weekly)
            case .monthly:
                rule = RepeatRule(frequency: .monthly)
            case .yearly:
                rule = RepeatRule(frequency: .yearly)
            case .weekdays where rule?.frequency != .weekdays:
                rule = RepeatRule(frequency: .weekdays, weekdays: [formatting.calendar.component(.weekday, from: day)])
            case .everyNDays where rule?.frequency != .everyNDays:
                rule = RepeatRule(frequency: .everyNDays, interval: 2)
            default:
                break
            }
        }
    }

    private func toggleWeekday(_ number: Int) {
        guard var updated = rule, updated.frequency == .weekdays else { return }
        if updated.weekdays.contains(number) {
            // Keep at least one day picked.
            guard updated.weekdays.count > 1 else { return }
            updated.weekdays.remove(number)
        } else {
            updated.weekdays.insert(number)
        }
        withAnimation(.snappy) { rule = updated }
    }
}

extension RepeatRule {
    /// Short text for the rule, like "Every day" or "Sat, Mon, Wed".
    func summary(formatting: DateFormatting) -> String {
        let language = formatting.language
        switch frequency {
        case .daily:
            return L10n.string("Every Day", language)
        case .weekly:
            return L10n.string("Every Week", language)
        case .monthly:
            return L10n.string("Every Month", language)
        case .yearly:
            return L10n.string("Every Year", language)
        case .everyNDays:
            return L10n.format("Every %lld days", language, interval)
        case .weekdays:
            let days = formatting.orderedWeekdays.filter { weekdays.contains($0.number) }
            if days.count == 7 {
                return L10n.string("Every Day", language)
            }
            return days.map(\.shortName).joined(separator: language == .farsi ? "\u{060C} " : ", ")
        }
    }
}
