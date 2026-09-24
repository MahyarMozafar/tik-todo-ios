import Foundation
import SwiftData
import WidgetKit

/// A task turned into plain values, ready to draw in a widget.
struct WidgetTask: Identifiable, Hashable {
    let id: UUID
    let title: String
    let isDone: Bool
    let time: String?
    let isLate: Bool
    let priority: Priority
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let doneCount: Int
    let totalCount: Int
    let preferences: Preferences

    var openCount: Int { totalCount - doneCount }
    var formatting: DateFormatting { preferences.formatting }
    var progress: Double { totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount) }
}

/// Reads today's tasks from the shared database.
enum WidgetData {
    static let container = try? SharedStore.makeContainer()

    static func todayEntry(at date: Date = .now) -> TodayEntry {
        UserDefaults.registerTikDefaults()
        let preferences = Preferences.current()
        let calendar = preferences.formatting.calendar

        guard let container else {
            return TodayEntry(date: date, tasks: [], doneCount: 0, totalCount: 0, preferences: preferences)
        }

        let context = ModelContext(container)
        let dated = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.dueDate != nil }))) ?? []
        let today = TaskFilter.today(dated, now: date, calendar: calendar, order: preferences.sortOrder)
        let shown = preferences.showCompletedInToday ? today : today.filter { !$0.isDone }

        let tasks = shown.map { task in
            let late = TaskFilter.isOverdue(task, now: date, calendar: calendar)
                || (!task.isDone && task.hasTime && (task.dueDate ?? date) < date)
            return WidgetTask(id: task.id,
                              title: task.title,
                              isDone: task.isDone,
                              time: task.hasTime ? task.dueDate.map(preferences.formatting.time) : nil,
                              isLate: late,
                              priority: task.priority)
        }

        return TodayEntry(date: date,
                          tasks: tasks,
                          doneCount: today.filter(\.isDone).count,
                          totalCount: today.count,
                          preferences: preferences)
    }

    /// The times later today when a task becomes late, so the widget can
    /// turn it red right on time.
    static func upcomingTimes(after date: Date) -> [Date] {
        guard let container else { return [] }
        let calendar = Preferences.current().formatting.calendar
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { !$0.isDone && $0.hasTime })
        let times = ((try? context.fetch(descriptor)) ?? []).compactMap(\.dueDate).filter { $0 > date && $0 < endOfDay }
        return Array(Set(times)).sorted()
    }
}

extension TodayEntry {
    /// Example content for the widget gallery.
    static func sample(preferences: Preferences = .current()) -> TodayEntry {
        let language = preferences.language
        let tasks = [
            WidgetTask(id: UUID(), title: L10n.string("Reply to emails", language), isDone: false,
                       time: preferences.formatting.time(.now.addingTimeInterval(3600)), isLate: false, priority: .high),
            WidgetTask(id: UUID(), title: L10n.string("Call mom", language), isDone: false,
                       time: nil, isLate: false, priority: .medium),
            WidgetTask(id: UUID(), title: L10n.string("Buy groceries", language), isDone: false,
                       time: nil, isLate: false, priority: .none),
            WidgetTask(id: UUID(), title: L10n.string("Morning run", language), isDone: true,
                       time: nil, isLate: false, priority: .none),
        ]
        return TodayEntry(date: .now, tasks: tasks, doneCount: 1, totalCount: 4, preferences: preferences)
    }
}
