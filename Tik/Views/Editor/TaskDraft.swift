import Foundation
import SwiftData

struct SubtaskDraft: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var isDone = false
}

/// A copy of a task's values that the editor can change freely.
/// Nothing touches the database until `apply(to:in:calendar:)` is called.
struct TaskDraft: Equatable {
    var title = ""
    var note = ""
    var list: TaskList?
    var priority: Priority = .none
    var hasDate = false
    var day = Date.now
    var hasTime = false
    var time = TaskDraft.nextFullHour()
    var repeatRule: RepeatRule?
    var subtasks: [SubtaskDraft] = []
    var photoData: Data?

    init(request: EditorRequest) {
        if let task = request.task {
            title = task.title
            note = task.note
            list = task.list
            priority = task.priority
            if let due = task.dueDate {
                hasDate = true
                day = due
                hasTime = task.hasTime
                if task.hasTime {
                    time = due
                }
            }
            repeatRule = task.repeatRule
            subtasks = task.sortedSubtasks.map { SubtaskDraft(id: $0.id, title: $0.title, isDone: $0.isDone) }
            photoData = task.hasPhoto ? task.photoData : nil
        } else {
            title = request.title
            list = request.list
            if let due = request.dueDate {
                hasDate = true
                day = due
            }
        }
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty
    }

    /// The due date made from `day` and `time`, or nil when there is no date.
    func dueDate(calendar: Calendar) -> Date? {
        guard hasDate else { return nil }
        let start = calendar.startOfDay(for: day)
        guard hasTime else { return start }
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0, second: 0, of: start)
    }

    /// Writes the draft into `task`, including adding, changing and removing subtasks.
    func apply(to task: TaskItem, in context: ModelContext, calendar: Calendar) {
        task.title = trimmedTitle
        task.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        task.list = list
        task.priority = priority
        task.dueDate = dueDate(calendar: calendar)
        task.hasTime = hasDate && hasTime
        task.repeatRule = hasDate ? repeatRule.map { rule in
            // Remember the day of the month, so monthly repeats stay on it.
            var rule = rule
            if let due = task.dueDate, rule.frequency == .monthly || rule.frequency == .yearly {
                rule.dayOfMonth = calendar.component(.day, from: due)
            }
            return rule
        } : nil
        if task.photoData != photoData {
            task.photoData = photoData
        }
        task.hasPhoto = photoData != nil

        let existing = Dictionary(task.subtasks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var kept = Set<UUID>()
        for (index, draft) in subtasks.enumerated() {
            let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }

            if let subtask = existing[draft.id] {
                subtask.title = title
                subtask.isDone = draft.isDone
                subtask.sortIndex = index
            } else {
                let subtask = Subtask(title: title, isDone: draft.isDone, sortIndex: index)
                subtask.id = draft.id
                context.insert(subtask)
                subtask.task = task
            }
            kept.insert(draft.id)
        }
        for subtask in task.subtasks where !kept.contains(subtask.id) {
            context.delete(subtask)
        }
    }

    /// The next full hour from now, a good guess for a new task's time.
    static func nextFullHour(after date: Date = .now, calendar: Calendar = .current) -> Date {
        let inAnHour = calendar.date(byAdding: .hour, value: 1, to: date) ?? date
        let hour = calendar.component(.hour, from: inAnHour)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: inAnHour) ?? inAnHour
    }
}
