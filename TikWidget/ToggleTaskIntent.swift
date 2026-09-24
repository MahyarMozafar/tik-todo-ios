import AppIntents
import Foundation
import SwiftData

/// Ticks or unticks a task right from the widget, without opening the app.
struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Tick Task"
    static let isDiscoverable = false

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: UUID) {
        self.taskID = taskID.uuidString
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.registerTikDefaults()
        guard let id = UUID(uuidString: taskID), let container = WidgetData.container else {
            return .result()
        }
        try WidgetActions.toggleTask(withID: id, in: ModelContext(container))
        return .result()
    }
}
