import Foundation
import UserNotifications

/// Local notifications for tasks that have a time.
///
/// Each task has at most one waiting notification, named after the task's
/// ID, so it is easy to move or remove when the task changes.
enum Reminders {
    static let categoryID = "task-reminder"
    static let doneActionID = "done"
    static let snoozeActionID = "snooze"
    static let snoozeMinutes = 10

    private static var center: UNUserNotificationCenter { .current() }

    /// Asks for permission if it was never asked.
    /// Returns true when notifications are allowed.
    @discardableResult
    static func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    static func isDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    /// The "Mark as Done" and "Remind Me Later" buttons, in the app's language.
    static func registerActions(language: AppLanguage) {
        let done = UNNotificationAction(identifier: doneActionID,
                                        title: L10n.string("Mark as Done", language),
                                        options: [],
                                        icon: UNNotificationActionIcon(systemImageName: "checkmark.circle"))
        let snooze = UNNotificationAction(identifier: snoozeActionID,
                                          title: L10n.format("Remind Me in %lld Minutes", language, snoozeMinutes),
                                          options: [],
                                          icon: UNNotificationActionIcon(systemImageName: "clock.arrow.circlepath"))
        let category = UNNotificationCategory(identifier: categoryID, actions: [done, snooze], intentIdentifiers: [])
        center.setNotificationCategories([category])
    }

    /// Makes the waiting notification match the task: adds it, moves it, or
    /// removes it.
    static func sync(_ task: TaskItem, preferences: Preferences = .current(), now: Date = .now) {
        let id = task.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard !task.isDone, task.hasTime, let due = task.dueDate else { return }

        let fireDate = due.addingTimeInterval(-Double(preferences.reminderOffset) * 60)
        guard fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = message(for: task, preferences: preferences)
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.threadIdentifier = task.list?.id.uuidString ?? "inbox"

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .current
        let parts = gregorian.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func remove(ids: [UUID]) {
        let identifiers = ids.map(\.uuidString)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Schedules all open tasks again, for example after the reminder time
    /// setting changed.
    static func resyncAll(_ tasks: [TaskItem], preferences: Preferences = .current()) {
        center.removeAllPendingNotificationRequests()
        for task in tasks {
            sync(task, preferences: preferences)
        }
    }

    /// Shows the same reminder again in a few minutes.
    static func snooze(_ content: UNNotificationContent, id: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeMinutes * 60), repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// The number on the app icon.
    static func setBadge(_ count: Int) {
        center.setBadgeCount(count)
    }

    /// "10:00 · Work · first line of the note"
    private static func message(for task: TaskItem, preferences: Preferences) -> String {
        var parts: [String] = []
        if let due = task.dueDate {
            parts.append(preferences.formatting.time(due))
        }
        if let list = task.list {
            parts.append(list.name)
        }
        if let firstLine = task.note.split(separator: "\n").first {
            parts.append(String(firstLine))
        }
        return parts.joined(separator: " \u{00B7} ")
    }
}
