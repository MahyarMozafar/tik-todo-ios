import Foundation
import SwiftData
@testable import Tik

/// A Gregorian calendar in the device's time zone, like the app uses.
let gregorian: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
}()

let persian: Calendar = {
    var calendar = Calendar(identifier: .persian)
    calendar.timeZone = .current
    return calendar
}()

func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// Keeps the test databases alive while their contexts are in use.
@MainActor private var containers: [ModelContainer] = []

/// A fresh database that only lives in memory.
@MainActor
func makeContext() throws -> ModelContext {
    let container = try SharedStore.makeContainer(inMemory: true)
    containers.append(container)
    return ModelContext(container)
}

@MainActor
func makeTask(_ title: String, due: Date? = nil, hasTime: Bool = false, priority: Priority = .none,
              in context: ModelContext) -> TaskItem {
    let task = TaskItem(title: title, dueDate: due, hasTime: hasTime, priority: priority)
    context.insert(task)
    return task
}
