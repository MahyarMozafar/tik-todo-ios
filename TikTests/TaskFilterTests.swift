import Foundation
import Testing
@testable import Tik

@MainActor
struct TaskFilterTests {
    /// Thursday, September 24, 2026, noon.
    let now = date(2026, 9, 24, 12)

    @Test func todayHasLateAndDueTasksButNotFutureOnes() throws {
        let context = try makeContext()
        let late = makeTask("late", due: date(2026, 9, 22), in: context)
        let today = makeTask("today", due: date(2026, 9, 24), in: context)
        let future = makeTask("future", due: date(2026, 9, 25), in: context)
        let noDate = makeTask("no date", in: context)

        let result = TaskFilter.today([late, today, future, noDate], now: now, calendar: gregorian, order: .time)
        #expect(result.map(\.title) == ["late", "today"])
    }

    @Test func doneTasksStayUntilTheDayEnds() throws {
        let context = try makeContext()
        let doneToday = makeTask("done today", due: date(2026, 9, 24), in: context)
        doneToday.isDone = true
        doneToday.completedAt = date(2026, 9, 24, 9)
        let doneYesterday = makeTask("done yesterday", due: date(2026, 9, 23), in: context)
        doneYesterday.isDone = true
        doneYesterday.completedAt = date(2026, 9, 23, 18)

        let tasks = [doneToday, doneYesterday]
        #expect(TaskFilter.today(tasks, now: now, calendar: gregorian, order: .time).map(\.title) == ["done today"])
        #expect(TaskFilter.today(tasks, now: now, calendar: gregorian, order: .time, includeCompleted: false).isEmpty)
    }

    @Test func sortingByTimePutsTimedTasksFirstAndDoneTasksLast() throws {
        let context = try makeContext()
        let done = makeTask("done", due: date(2026, 9, 24), in: context)
        done.isDone = true
        done.completedAt = now
        let noon = makeTask("noon", due: date(2026, 9, 24, 12), hasTime: true, in: context)
        let morning = makeTask("morning", due: date(2026, 9, 24, 8), hasTime: true, in: context)
        let anytime = makeTask("anytime", due: date(2026, 9, 24), priority: .high, in: context)

        let sorted = TaskFilter.sorted([done, noon, anytime, morning], order: .time, now: now, calendar: gregorian)
        #expect(sorted.map(\.title) == ["morning", "noon", "anytime", "done"])
    }

    @Test func sortingByPriorityPutsImportantTasksFirst() throws {
        let context = try makeContext()
        let low = makeTask("low", due: date(2026, 9, 24, 8), hasTime: true, priority: .low, in: context)
        let high = makeTask("high", due: date(2026, 9, 24), priority: .high, in: context)
        let none = makeTask("none", due: date(2026, 9, 24, 7), hasTime: true, in: context)

        let sorted = TaskFilter.sorted([low, none, high], order: .priority, now: now, calendar: gregorian)
        #expect(sorted.map(\.title) == ["high", "low", "none"])
    }

    @Test func lateTasksAlwaysComeFirst() throws {
        let context = try makeContext()
        let early = makeTask("early today", due: date(2026, 9, 24, 6), hasTime: true, in: context)
        let late = makeTask("from yesterday", due: date(2026, 9, 23), in: context)

        let sorted = TaskFilter.sorted([early, late], order: .time, now: now, calendar: gregorian)
        #expect(sorted.map(\.title) == ["from yesterday", "early today"])
    }

    @Test func scheduledGroupsUpcomingTasksByDay() throws {
        let context = try makeContext()
        let a = makeTask("a", due: date(2026, 9, 25, 9), hasTime: true, in: context)
        let b = makeTask("b", due: date(2026, 9, 27), in: context)
        let c = makeTask("c", due: date(2026, 9, 25), in: context)
        let today = makeTask("today", due: date(2026, 9, 24), in: context)

        let groups = TaskFilter.scheduled([a, b, c, today], now: now, calendar: gregorian, order: .time)
        #expect(groups.map(\.day) == [date(2026, 9, 25), date(2026, 9, 27)])
        #expect(groups[0].tasks.map(\.title) == ["a", "c"])
    }

    @Test func searchLooksAtTitlesNotesAndSubtasks() throws {
        let context = try makeContext()
        let task = makeTask("Groceries", in: context)
        task.note = "Call the bank first"
        let subtask = Subtask(title: "Eggs")
        context.insert(subtask)
        subtask.task = task

        #expect(TaskFilter.matches(task, query: "grocer"))
        #expect(TaskFilter.matches(task, query: "BANK"))
        #expect(TaskFilter.matches(task, query: "eggs"))
        #expect(!TaskFilter.matches(task, query: "milk"))
        #expect(!TaskFilter.matches(task, query: "   "))
    }
}
