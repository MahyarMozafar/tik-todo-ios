import Foundation
import SwiftData

/// Small database questions that the app, the widget and intents all ask.
enum TaskQueries {
    /// How many tasks are still open for today, late ones included.
    static func openTodayCount(in context: ModelContext, calendar: Calendar, now: Date = .now) -> Int {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let never = Date.distantFuture
        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { task in
            !task.isDone && (task.dueDate ?? never) < startOfTomorrow
        })
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    static func task(withID id: UUID, in context: ModelContext) -> TaskItem? {
        var descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func openTasks(in context: ModelContext) -> [TaskItem] {
        (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isDone }))) ?? []
    }
}
