import Foundation

/// What the task editor should open with.
struct EditorRequest: Identifiable {
    let id = UUID()

    /// The task to edit, or nil for a new task.
    var task: TaskItem?

    /// Starting values for a new task.
    var title = ""
    var dueDate: Date?
    var list: TaskList?

    static func edit(_ task: TaskItem) -> EditorRequest {
        EditorRequest(task: task)
    }

    static func new(title: String = "", dueDate: Date? = nil, list: TaskList? = nil) -> EditorRequest {
        EditorRequest(task: nil, title: title, dueDate: dueDate, list: list)
    }
}
