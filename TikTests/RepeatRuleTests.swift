import Foundation
import Testing
@testable import Tik

struct RepeatRuleTests {
    /// Thursday, September 24, 2026, 10:00.
    let now = date(2026, 9, 24, 10)

    @Test func dailyGoesToTomorrow() {
        let next = RepeatRule(frequency: .daily).nextDueDate(after: date(2026, 9, 24), now: now, calendar: gregorian)
        #expect(next == date(2026, 9, 25))
    }

    @Test func aLateDailyTaskComesBackTomorrowNotInThePast() {
        let next = RepeatRule(frequency: .daily).nextDueDate(after: date(2026, 9, 20), now: now, calendar: gregorian)
        #expect(next == date(2026, 9, 25))
    }

    @Test func keepsTheTimeOfDay() {
        let next = RepeatRule(frequency: .daily).nextDueDate(after: date(2026, 9, 24, 7, 30), now: now, calendar: gregorian)
        #expect(next == date(2026, 9, 25, 7, 30))
    }

    @Test func weeklyKeepsTheWeekday() {
        // Due on Monday, September 7, and ticked weeks later on a Thursday.
        let next = RepeatRule(frequency: .weekly).nextDueDate(after: date(2026, 9, 7), now: now, calendar: gregorian)
        #expect(next == date(2026, 9, 28))
        #expect(gregorian.component(.weekday, from: next) == 2)
    }

    @Test func certainWeekdaysPicksTheNextOne() {
        // Saturday, Monday and Wednesday. Ticked on Thursday, so Saturday is next.
        let rule = RepeatRule(frequency: .weekdays, weekdays: [7, 2, 4])
        #expect(rule.nextDueDate(after: date(2026, 9, 24), now: now, calendar: gregorian) == date(2026, 9, 26))
    }

    @Test func everyFewDays() {
        let rule = RepeatRule(frequency: .everyNDays, interval: 3)
        #expect(rule.nextDueDate(after: date(2026, 9, 24), now: now, calendar: gregorian) == date(2026, 9, 27))
    }

    @Test func monthlyFromThe31stDoesNotDrift() {
        // Due January 31 and ticked in early March: the next one is March 31, not March 28.
        let next = RepeatRule(frequency: .monthly).nextDueDate(after: date(2026, 1, 31), now: date(2026, 3, 5, 9),
                                                                calendar: gregorian)
        #expect(next == date(2026, 3, 31))
    }

    @Test func monthlyGoesBackToThe31stAfterAShortMonth() {
        // January 31 became February 28; the next one is March 31 again.
        var rule = RepeatRule(frequency: .monthly)
        rule.dayOfMonth = 31
        let next = rule.nextDueDate(after: date(2026, 2, 28), now: date(2026, 2, 28, 9), calendar: gregorian)
        #expect(next == date(2026, 3, 31))

        // Without the remembered day, it would stay on the 28th.
        let plain = RepeatRule(frequency: .monthly)
        #expect(plain.nextDueDate(after: date(2026, 2, 28), now: date(2026, 2, 28, 9), calendar: gregorian)
                == date(2026, 3, 28))
    }

    @Test func monthlyWithShamsiFollowsShamsiMonths() {
        // 1 Mehr 1405 is followed by 1 Aban 1405.
        let due = persian.date(from: DateComponents(year: 1405, month: 7, day: 1))!
        let next = RepeatRule(frequency: .monthly).nextDueDate(after: due, now: due, calendar: persian)
        let parts = persian.dateComponents([.year, .month, .day], from: next)
        #expect(parts.year == 1405 && parts.month == 8 && parts.day == 1)
    }

    @Test func survivesSavingAsJSON() throws {
        let rule = RepeatRule(frequency: .weekdays, weekdays: [1, 3, 5], interval: 4)
        let data = try JSONEncoder().encode(rule)
        #expect(try JSONDecoder().decode(RepeatRule.self, from: data) == rule)
    }
}
