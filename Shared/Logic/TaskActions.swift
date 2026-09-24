import Foundation
import SwiftData

/// Changes to tasks that the app, the widget and App Intents all share.
enum TaskActions {
    struct ToggleResult {
        /// True when the task is now done.
        var isDone: Bool
        /// The next copy of a repeating task, made when it was ticked.
        var nextOccurrence: TaskItem?
        /// Copies that were removed because a tick was undone.
        var removedIDs: [UUID] = []
    }

    /// Ticks or unticks a task.
    ///
    /// Ticking a repeating task also makes its next copy. Unticking it removes
    /// that copy again, as long as the copy itself was not ticked yet.
    @discardableResult
    static func toggle(_ task: TaskItem, in context: ModelContext, calendar: Calendar, now: Date = .now) -> ToggleResult {
        if task.isDone {
            task.isDone = false
            task.completedAt = nil
            return ToggleResult(isDone: false, removedIDs: deleteNextOccurrence(of: task, in: context))
        }

        task.isDone = true
        task.completedAt = now
        let next = task.repeatRule.map { makeNextOccurrence(of: task, rule: $0, in: context, calendar: calendar, now: now) }
        return ToggleResult(isDone: true, nextOccurrence: next)
    }

    static func makeNextOccurrence(of task: TaskItem, rule: RepeatRule, in context: ModelContext,
                                   calendar: Calendar, now: Date) -> TaskItem {
        let due = task.dueDate ?? calendar.startOfDay(for: now)
        let next = TaskItem(title: task.title,
                            dueDate: rule.nextDueDate(after: due, now: now, calendar: calendar),
                            hasTime: task.hasTime,
                            priority: task.priority)
        next.note = task.note
        next.repeatRuleJSON = task.repeatRuleJSON
        next.photoData = task.photoData
        next.previousOccurrenceID = task.id
        context.insert(next)
        next.list = task.list

        for subtask in task.sortedSubtasks {
            let copy = Subtask(title: subtask.title, sortIndex: subtask.sortIndex)
            context.insert(copy)
            copy.task = next
        }
        return next
    }

    /// Removes the not-yet-done copy made when `task` was ticked.
    /// Returns the IDs of what was removed.
    @discardableResult
    static func deleteNextOccurrence(of task: TaskItem, in context: ModelContext) -> [UUID] {
        let id: UUID? = task.id
        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.previousOccurrenceID == id && !$0.isDone })
        let copies = (try? context.fetch(descriptor)) ?? []
        for copy in copies {
            context.delete(copy)
        }
        return copies.map(\.id)
    }

    /// Moves a task to tomorrow, keeping its time of day.
    static func moveToTomorrow(_ task: TaskItem, calendar: Calendar, now: Date = .now) {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        if task.hasTime, let due = task.dueDate {
            let time = calendar.dateComponents([.hour, .minute], from: due)
            task.dueDate = calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: tomorrow)
        } else {
            task.dueDate = tomorrow
            task.hasTime = false
        }
    }

    /// Makes a fresh, not-done copy of a task.
    @discardableResult
    static func duplicate(_ task: TaskItem, in context: ModelContext) -> TaskItem {
        let copy = TaskItem(title: task.title, dueDate: task.dueDate, hasTime: task.hasTime, priority: task.priority)
        copy.note = task.note
        copy.repeatRuleJSON = task.repeatRuleJSON
        copy.photoData = task.photoData
        context.insert(copy)
        copy.list = task.list

        for subtask in task.sortedSubtasks {
            let subtaskCopy = Subtask(title: subtask.title, sortIndex: subtask.sortIndex)
            context.insert(subtaskCopy)
            subtaskCopy.task = copy
        }
        return copy
    }
}
