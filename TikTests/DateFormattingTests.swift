import Foundation
import Testing
@testable import Tik

struct DateFormattingTests {
    /// Thursday, September 24, 2026 is 2 Mehr 1405 in the Shamsi calendar.
    let day = date(2026, 9, 24, 7, 5)

    @Test func shamsiInEnglish() {
        let formatting = DateFormatting(language: .english, calendarKind: .persian, use24Hour: true)
        #expect(formatting.fullDay(day) == "Thursday, Mehr 2")
        #expect(formatting.time(day) == "07:05")
    }

    @Test func gregorianInEnglish() {
        let formatting = DateFormatting(language: .english, calendarKind: .gregorian, use24Hour: true)
        #expect(formatting.fullDay(day) == "Thursday, September 24")
    }

    @Test func twelveHourTime() {
        let formatting = DateFormatting(language: .english, calendarKind: .gregorian, use24Hour: false)
        #expect(formatting.time(day).hasPrefix("7:05"))
        #expect(formatting.time(day).hasSuffix("AM"))
    }

    @Test func farsiAlwaysUsesEnglishDigits() {
        let formatting = DateFormatting(language: .farsi, calendarKind: .persian, use24Hour: true)
        let text = formatting.dayAndMonth(day) + formatting.time(day)
        let persianDigits = CharacterSet(charactersIn: "\u{06F0}"..."\u{06F9}")
        #expect(text.contains("2"))
        #expect(text.unicodeScalars.allSatisfy { !persianDigits.contains($0) })
    }

    @Test func shamsiWeeksStartOnSaturday() {
        let formatting = DateFormatting(language: .english, calendarKind: .persian, use24Hour: true)
        #expect(formatting.orderedWeekdays.first?.number == 7)
        #expect(formatting.orderedWeekdays.map(\.number) == [7, 1, 2, 3, 4, 5, 6])
    }

    @Test func relativeDays() {
        let formatting = DateFormatting(language: .english, calendarKind: .gregorian, use24Hour: true)
        #expect(formatting.relativeDay(date(2026, 9, 24), now: day) == "Today")
        #expect(formatting.relativeDay(date(2026, 9, 25), now: day) == "Tomorrow")
        #expect(formatting.relativeDay(date(2026, 9, 23), now: day) == "Yesterday")
        #expect(formatting.relativeDay(date(2026, 9, 27), now: day) == "Sunday")
    }
}
