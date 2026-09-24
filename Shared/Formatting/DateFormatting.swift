import Foundation

/// Turns dates into text the way the user picked in Settings:
/// Shamsi or Gregorian calendar, English or Farsi words, and always
/// English digits (for example "Wednesday, Mehr 2" or "07:30").
struct DateFormatting: Equatable {
    let language: AppLanguage
    let calendar: Calendar
    let locale: Locale

    init(language: AppLanguage, calendarKind: CalendarKind, use24Hour: Bool) {
        var components = Locale.Components(identifier: language == .farsi ? "fa_IR" : "en_US")
        components.calendar = calendarKind.identifier
        components.numberingSystem = Locale.NumberingSystem("latn")
        components.hourCycle = use24Hour ? .zeroToTwentyThree : .oneToTwelve
        let locale = Locale(components: components)

        var calendar = Calendar(identifier: calendarKind.identifier)
        calendar.locale = locale
        calendar.timeZone = .current
        // Weeks start on Saturday in Iran.
        calendar.firstWeekday = (calendarKind == .persian || language == .farsi) ? 7 : 1

        self.language = language
        self.calendar = calendar
        self.locale = locale
    }

    private var style: Date.FormatStyle {
        Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }

    /// "Wednesday, Mehr 2"
    func fullDay(_ date: Date) -> String {
        date.formatted(style.weekday(.wide).month(.wide).day())
    }

    /// "Wednesday"
    func weekday(_ date: Date) -> String {
        date.formatted(style.weekday(.wide))
    }

    /// "Mehr 2"
    func dayAndMonth(_ date: Date) -> String {
        date.formatted(style.month(.wide).day())
    }

    /// "Sat, Mehr 5"
    func shortDay(_ date: Date) -> String {
        date.formatted(style.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// "Mehr 5, 1405"
    func dayMonthYear(_ date: Date) -> String {
        date.formatted(style.year().month(.abbreviated).day())
    }

    /// "07:30", or "7:30 AM" when 24-hour time is off.
    func time(_ date: Date) -> String {
        date.formatted(style.hour().minute())
    }

    /// "Today", "Tomorrow", "Yesterday", a weekday for the next few days,
    /// or a short date.
    func relativeDay(_ date: Date, now: Date = .now) -> String {
        let today = calendar.startOfDay(for: now)
        let day = calendar.startOfDay(for: date)
        let distance = calendar.dateComponents([.day], from: today, to: day).day ?? 0

        switch distance {
        case 0: return L10n.string("Today", language)
        case 1: return L10n.string("Tomorrow", language)
        case -1: return L10n.string("Yesterday", language)
        case 2...6: return weekday(date)
        default:
            let sameYear = calendar.isDate(date, equalTo: now, toGranularity: .year)
            return sameYear ? shortDay(date) : dayMonthYear(date)
        }
    }

    /// The days of the week in the order the week starts, with their
    /// `Calendar` numbers (1 is Sunday).
    var orderedWeekdays: [(number: Int, shortName: String, letter: String)] {
        let short = calendar.shortWeekdaySymbols
        let letters = calendar.veryShortWeekdaySymbols
        return (0..<7).map { offset in
            let number = (calendar.firstWeekday - 1 + offset) % 7 + 1
            return (number, short[number - 1], letters[number - 1])
        }
    }
}
