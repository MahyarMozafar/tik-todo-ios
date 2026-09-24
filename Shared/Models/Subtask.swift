import Foundation
import SwiftData

@Model
final class Subtask {
    var id: UUID = UUID()
    var title: String = ""
    var isDone: Bool = false
    var sortIndex: Int = 0
    var task: TaskItem?

    init(title: String, isDone: Bool = false, sortIndex: Int = 0) {
        self.title = title
        self.isDone = isDone
        self.sortIndex = sortIndex
    }
}
