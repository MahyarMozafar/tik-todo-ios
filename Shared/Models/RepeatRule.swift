import Foundation

/// How a task comes back after it is done.
struct RepeatRule: Codable, Hashable, Sendable {
    enum Frequency: String, Codable, CaseIterable, Sendable {
        case daily
        case weekdays
        case weekly
        case monthly
        case yearly
        case everyNDays
    }

    var frequency: Frequency

    /// Only for `.weekdays`. Uses `Calendar` numbers: 1 is Sunday, 7 is Saturday.
    var weekdays: Set<Int> = []

    /// Only for `.everyNDays`.
    var interval: Int = 2

    /// Only for `.monthly` and `.yearly`: the day of the month the task
    /// started on. A task on the 31st moves to the 28th in February, and
    /// this brings it back to the 31st in the months that have one.
    var dayOfMonth: Int?

    /// When a repeating task is ticked, its next copy goes on this date.
    ///
    /// The date is always after `due`, and never on a day that has already
    /// started, so a task that was late does not come back as late again.
    /// Monthly and yearly repeats keep to `dayOfMonth`, so the 31st does not
    /// slowly drift to the 28th.
    func nextDueDate(after due: Date, now: Date, calendar: Calendar) -> Date {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!

        if frequency == .weekdays, !weekdays.isEmpty {
            var candidate = due
            repeat {
                candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
            } while candidate < startOfTomorrow || !weekdays.contains(calendar.component(.weekday, from: candidate))
            return candidate
        }

        let (component, size) = step
        var count = 1
        while true {
            let candidate = keepingDayOfMonth(calendar.date(byAdding: component, value: size * count, to: due)!,
                                              calendar: calendar)
            if candidate >= startOfTomorrow {
                return candidate
            }
            count += 1
        }
    }

    /// Moves a monthly or yearly date back to `dayOfMonth`, as far as the
    /// month allows (the 31st becomes the 30th in a 30-day month).
    private func keepingDayOfMonth(_ date: Date, calendar: Calendar) -> Date {
        guard frequency == .monthly || frequency == .yearly,
              let dayOfMonth,
              let days = calendar.range(of: .day, in: .month, for: date) else { return date }
        var parts = calendar.dateComponents([.era, .year, .month, .hour, .minute, .second], from: date)
        parts.day = min(dayOfMonth, days.count)
        return calendar.date(from: parts) ?? date
    }

    private var step: (Calendar.Component, Int) {
        switch frequency {
        case .daily, .weekdays: (.day, 1)
        case .weekly: (.day, 7)
        case .monthly: (.month, 1)
        case .yearly: (.year, 1)
        case .everyNDays: (.day, max(1, interval))
        }
    }
}
