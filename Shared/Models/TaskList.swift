import Foundation
import SwiftData

@Model
final class TaskList {
    var id: UUID = UUID()
    var name: String = ""
    /// An SF Symbol name.
    var symbol: String = "list.bullet"
    /// The raw value of an `AccentChoice`.
    var colorName: String = "blue"
    var sortIndex: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list)
    var tasks: [TaskItem] = []

    init(name: String, symbol: String = "list.bullet", colorName: String = "blue", sortIndex: Int = 0) {
        self.name = name
        self.symbol = symbol
        self.colorName = colorName
        self.sortIndex = sortIndex
    }
}

extension TaskList {
    var color: AccentChoice {
        AccentChoice(rawValue: colorName) ?? .blue
    }

    var openTaskCount: Int {
        tasks.filter { !$0.isDone }.count
    }
}
