import Foundation
import Testing
@testable import Tik

@MainActor
struct TaskDraftTests {
    @Test func dueDateJoinsTheDayAndTheTime() {
        var draft = TaskDraft(request: .new())
        draft.hasDate = true
        draft.day = date(2026, 9, 24, 15)
        draft.hasTime = true
        draft.time = date(2020, 1, 1, 7, 30)
        #expect(draft.dueDate(calendar: gregorian) == date(2026, 9, 24, 7, 30))

        draft.hasTime = false
        #expect(draft.dueDate(calendar: gregorian) == date(2026, 9, 24))

        draft.hasDate = false
        #expect(draft.dueDate(calendar: gregorian) == nil)
    }

    @Test func applyAddsChangesAndRemovesSubtasks() throws {
        let context = try makeContext()
        let task = makeTask("Trip", in: context)
        for (index, title) in ["Passport", "Tickets"].enumerated() {
            let subtask = Subtask(title: title, sortIndex: index)
            context.insert(subtask)
            subtask.task = task
        }

        var draft = TaskDraft(request: .edit(task))
        draft.subtasks[0].isDone = true
        draft.subtasks.remove(at: 1)
        draft.subtasks.append(SubtaskDraft(title: "Bag"))
        draft.subtasks.append(SubtaskDraft(title: "   "))
        draft.apply(to: task, in: context, calendar: gregorian)
        try context.save()

        #expect(task.sortedSubtasks.map(\.title) == ["Passport", "Bag"])
        #expect(task.sortedSubtasks.first?.isDone == true)
    }

    @Test func removingTheDateAlsoRemovesTheRepeat() throws {
        let context = try makeContext()
        let task = makeTask("Water plants", due: date(2026, 9, 24), in: context)
        task.repeatRule = RepeatRule(frequency: .daily)

        var draft = TaskDraft(request: .edit(task))
        draft.hasDate = false
        draft.apply(to: task, in: context, calendar: gregorian)

        #expect(task.dueDate == nil)
        #expect(task.repeatRule == nil)
    }

    @Test func monthlyRepeatRemembersTheDayOfTheMonth() throws {
        let context = try makeContext()
        let task = makeTask("Pay rent", in: context)

        var draft = TaskDraft(request: .edit(task))
        draft.hasDate = true
        draft.day = date(2026, 1, 31)
        draft.repeatRule = RepeatRule(frequency: .monthly)
        draft.apply(to: task, in: context, calendar: gregorian)

        #expect(task.repeatRule?.dayOfMonth == 31)
    }

    @Test func titleIsTrimmedAndRequired() {
        var draft = TaskDraft(request: .new(title: "  Buy milk  "))
        #expect(draft.trimmedTitle == "Buy milk")
        #expect(draft.canSave)

        draft.title = "   "
        #expect(!draft.canSave)
    }
}
