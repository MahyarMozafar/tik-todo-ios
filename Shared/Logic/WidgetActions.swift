import Foundation
import SwiftData

/// What happens when a task is ticked outside the app (on the widget).
enum WidgetActions {
    /// Ticks or unticks the task with this ID, saves, and brings reminders and
    /// the badge up to date. Returns false when the task can't be found.
    @discardableResult
    static func toggleTask(withID id: UUID, in context: ModelContext,
                           preferences: Preferences = .current(),
                           defaults: UserDefaults = .tik,
                           now: Date = .now) throws -> Bool {
        let calendar = preferences.formatting.calendar
        guard let task = TaskQueries.task(withID: id, in: context) else { return false }

        let result = TaskActions.toggle(task, in: context, calendar: calendar, now: now)
        try context.save()

        Reminders.sync(task, preferences: preferences)
        if let next = result.nextOccurrence {
            Reminders.sync(next, preferences: preferences)
        }
        Reminders.remove(ids: result.removedIDs)
        if preferences.showsBadge {
            Reminders.setBadge(TaskQueries.openTodayCount(in: context, calendar: calendar))
        }

        // Tell the app its copy of the data is old.
        defaults.set(now.timeIntervalSince1970, forKey: PrefKey.externalChange)
        return true
    }
}
