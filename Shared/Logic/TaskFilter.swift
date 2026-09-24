import Foundation

/// Decides which tasks show up on each screen, and in what order.
/// Everything here is a plain function, so it is easy to test.
enum TaskFilter {
    // MARK: Today

    /// A task is on Today when it is due today or late. A done task stays on
    /// Today until the day ends, unless `includeCompleted` is false.
    static func isOnToday(_ task: TaskItem, now: Date, calendar: Calendar, includeCompleted: Bool = true) -> Bool {
        guard let due = task.dueDate else { return false }
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        if task.isDone {
            guard includeCompleted, let completedAt = task.completedAt else { return false }
            return completedAt >= startOfToday && due < startOfTomorrow
        }
        return due < startOfTomorrow
    }

    static func today(_ tasks: [TaskItem], now: Date, calendar: Calendar,
                      order: TaskSortOrder, includeCompleted: Bool = true) -> [TaskItem] {
        let onToday = tasks.filter { isOnToday($0, now: now, calendar: calendar, includeCompleted: includeCompleted) }
        return sorted(onToday, order: order, now: now, calendar: calendar)
    }

    static func isOverdue(_ task: TaskItem, now: Date, calendar: Calendar) -> Bool {
        guard !task.isDone, let due = task.dueDate else { return false }
        return due < calendar.startOfDay(for: now)
    }

    // MARK: Other screens

    /// Open tasks with a date after today, grouped by day.
    static func scheduled(_ tasks: [TaskItem], now: Date, calendar: Calendar,
                          order: TaskSortOrder) -> [(day: Date, tasks: [TaskItem])] {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let upcoming = tasks.filter { task in
            guard !task.isDone, let due = task.dueDate else { return false }
            return due >= startOfTomorrow
        }
        let groups = Dictionary(grouping: upcoming) { calendar.startOfDay(for: $0.dueDate!) }
        return groups.keys.sorted().map { day in
            (day, sorted(groups[day]!, order: order, now: now, calendar: calendar))
        }
    }

    /// Done tasks grouped by the day they were done, newest day first.
    static func completed(_ tasks: [TaskItem], calendar: Calendar) -> [(day: Date, tasks: [TaskItem])] {
        let done = tasks.filter(\.isDone)
        let groups = Dictionary(grouping: done) { calendar.startOfDay(for: $0.completedAt ?? $0.createdAt) }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day]!.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
        }
    }

    /// Matches the title, the note, or any subtask.
    static func matches(_ task: TaskItem, query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return false }
        return task.title.localizedStandardContains(query)
            || task.note.localizedStandardContains(query)
            || task.subtasks.contains { $0.title.localizedStandardContains(query) }
    }

    // MARK: Sorting

    /// Open tasks first, in the chosen order. Done tasks go to the bottom,
    /// the most recently done first.
    static func sorted(_ tasks: [TaskItem], order: TaskSortOrder, now: Date, calendar: Calendar) -> [TaskItem] {
        let startOfToday = calendar.startOfDay(for: now)
        let open = tasks.filter { !$0.isDone }.sorted { comesBefore($0, $1, order: order, startOfToday: startOfToday) }
        let done = tasks.filter(\.isDone).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        return open + done
    }

    static func comesBefore(_ a: TaskItem, _ b: TaskItem, order: TaskSortOrder, startOfToday: Date) -> Bool {
        if order == .newest {
            return a.createdAt > b.createdAt
        }

        // Late tasks always come first.
        let aLate = (a.dueDate ?? .distantFuture) < startOfToday
        let bLate = (b.dueDate ?? .distantFuture) < startOfToday
        if aLate != bLate { return aLate }

        if order == .priority, a.priorityRaw != b.priorityRaw {
            return a.priorityRaw > b.priorityRaw
        }

        // Tasks with a time come before tasks without one, earliest first.
        let aTime = a.hasTime ? a.dueDate : nil
        let bTime = b.hasTime ? b.dueDate : nil
        switch (aTime, bTime) {
        case let (aTime?, bTime?) where aTime != bTime:
            return aTime < bTime
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            break
        }

        if a.priorityRaw != b.priorityRaw {
            return a.priorityRaw > b.priorityRaw
        }
        return a.createdAt < b.createdAt
    }
}
