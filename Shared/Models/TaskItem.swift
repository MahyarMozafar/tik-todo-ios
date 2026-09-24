import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var note: String = ""
    var isDone: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date.now

    /// The day the task is for. When `hasTime` is false this is the start of that day.
    var dueDate: Date?
    var hasTime: Bool = false

    var priorityRaw: Int = 0

    /// A `RepeatRule` saved as JSON, or nil when the task does not repeat.
    var repeatRuleJSON: String?

    @Attribute(.externalStorage)
    var photoData: Data?

    /// Set on the copy that is made when a repeating task is ticked, so the copy
    /// can be removed again if the tick is undone.
    var previousOccurrenceID: UUID?

    var list: TaskList?

    @Relationship(deleteRule: .cascade, inverse: \Subtask.task)
    var subtasks: [Subtask] = []

    init(title: String, dueDate: Date? = nil, hasTime: Bool = false, priority: Priority = .none) {
        self.title = title
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.priorityRaw = priority.rawValue
    }
}

extension TaskItem {
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    var repeatRule: RepeatRule? {
        get {
            guard let repeatRuleJSON else { return nil }
            return try? JSONDecoder().decode(RepeatRule.self, from: Data(repeatRuleJSON.utf8))
        }
        set {
            guard let newValue, let data = try? JSONEncoder().encode(newValue) else {
                repeatRuleJSON = nil
                return
            }
            repeatRuleJSON = String(decoding: data, as: UTF8.self)
        }
    }

    var sortedSubtasks: [Subtask] {
        subtasks.sorted { $0.sortIndex < $1.sortIndex }
    }

    var doneSubtaskCount: Int {
        subtasks.filter(\.isDone).count
    }
}
