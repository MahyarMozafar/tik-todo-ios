import Foundation
import Testing
@testable import Tik

@MainActor
struct TaskActionsTests {
    @Test func tickingARepeatingTaskMakesTheNextOne() throws {
        let context = try makeContext()
        let task = makeTask("Read", due: date(2026, 9, 24, 21, 30), hasTime: true, in: context)
        task.repeatRule = RepeatRule(frequency: .daily)
        let subtask = Subtask(title: "Chapter 3", isDone: true)
        context.insert(subtask)
        subtask.task = task

        let result = TaskActions.toggle(task, in: context, calendar: gregorian, now: date(2026, 9, 24, 22))

        #expect(result.isDone)
        #expect(task.completedAt == date(2026, 9, 24, 22))
        let next = try #require(result.nextOccurrence)
        #expect(next.title == "Read")
        #expect(next.dueDate == date(2026, 9, 25, 21, 30))
        #expect(next.repeatRule == RepeatRule(frequency: .daily))
        #expect(next.previousOccurrenceID == task.id)
        // Subtasks come along, but not ticked.
        #expect(next.subtasks.map(\.title) == ["Chapter 3"])
        #expect(next.subtasks.allSatisfy { !$0.isDone })
    }

    @Test func untickingRemovesTheCopyAgain() throws {
        let context = try makeContext()
        let task = makeTask("Gym", due: date(2026, 9, 24), in: context)
        task.repeatRule = RepeatRule(frequency: .weekly)

        let ticked = TaskActions.toggle(task, in: context, calendar: gregorian, now: date(2026, 9, 24, 8))
        let next = try #require(ticked.nextOccurrence)
        try context.save()

        let unticked = TaskActions.toggle(task, in: context, calendar: gregorian)
        #expect(!unticked.isDone)
        #expect(task.completedAt == nil)
        #expect(unticked.removedIDs == [next.id])
    }

    @Test func tickingANormalTaskMakesNoCopy() throws {
        let context = try makeContext()
        let task = makeTask("Call mom", due: date(2026, 9, 24), in: context)

        let result = TaskActions.toggle(task, in: context, calendar: gregorian)
        #expect(result.isDone)
        #expect(result.nextOccurrence == nil)
    }

    @Test func moveToTomorrowKeepsTheTime() throws {
        let context = try makeContext()
        let task = makeTask("Meeting", due: date(2026, 9, 24, 11, 15), hasTime: true, in: context)

        TaskActions.moveToTomorrow(task, calendar: gregorian, now: date(2026, 9, 24, 9))
        #expect(task.dueDate == date(2026, 9, 25, 11, 15))
    }

    @Test func duplicateMakesAnOpenCopy() throws {
        let context = try makeContext()
        let task = makeTask("Pack", due: date(2026, 9, 24), priority: .high, in: context)
        task.note = "Passport!"
        task.isDone = true

        let copy = TaskActions.duplicate(task, in: context)
        #expect(copy.id != task.id)
        #expect(copy.title == "Pack")
        #expect(copy.note == "Passport!")
        #expect(copy.priority == .high)
        #expect(!copy.isDone)
    }
}
