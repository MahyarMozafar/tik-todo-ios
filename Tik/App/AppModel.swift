import SwiftData
import SwiftUI
import WidgetKit

enum AppTab: Hashable {
    case today
    case lists
    case search
}

/// App-wide state, and the actions that change tasks.
///
/// Every change goes through here, so saving, the widget, reminders and the
/// app badge stay in step no matter which screen made the change.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    let container: ModelContainer

    /// The context all screens read from. It is replaced after the widget
    /// changes tasks, because the widget runs in its own process.
    private(set) var context: ModelContext

    /// Changes whenever `context` is replaced, so screens reload their data.
    private(set) var contextID = UUID()

    var selectedTab: AppTab = .today

    /// Set when the widget's + button opens the app. Today then opens its
    /// quick add field and clears this.
    var pendingQuickAdd = false

    /// Goes up by one each time the last open task of today is ticked.
    private(set) var celebrations = 0

    @ObservationIgnored private var lastExternalChange: Double

    init() {
        UserDefaults.registerTikDefaults()

        let container: ModelContainer
        do {
            container = try SharedStore.makeContainer()
        } catch {
            // Keep the app usable even if the database can't be opened.
            print("Tik: could not open the database: \(error)")
            container = try! SharedStore.makeContainer(inMemory: true)
        }
        self.container = container
        self.context = container.mainContext
        self.lastExternalChange = UserDefaults.tik.double(forKey: PrefKey.externalChange)

        createStarterListsIfNeeded()
    }

    var preferences: Preferences { .current() }

    var calendar: Calendar { preferences.formatting.calendar }

    // MARK: - Saving

    func save() {
        do {
            try context.save()
        } catch {
            print("Tik: could not save: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
        updateBadge()
    }

    /// Shows the number of open tasks for today on the app icon, when that
    /// is turned on in Settings.
    func updateBadge() {
        let preferences = preferences
        let count = preferences.showsBadge
            ? TaskQueries.openTodayCount(in: context, calendar: preferences.formatting.calendar)
            : 0
        Reminders.setBadge(count)
    }

    // MARK: - Tasks

    @discardableResult
    func addTask(title: String, dueDate: Date?, list: TaskList? = nil) -> TaskItem {
        let task = TaskItem(title: title.trimmingCharacters(in: .whitespacesAndNewlines), dueDate: dueDate)
        context.insert(task)
        task.list = list
        save()
        return task
    }

    /// Saves what the editor changed. With no `task`, a new task is made.
    func save(_ draft: TaskDraft, to task: TaskItem?) {
        let target: TaskItem
        if let task {
            target = task
        } else {
            target = TaskItem(title: draft.trimmedTitle)
            context.insert(target)
        }
        draft.apply(to: target, in: context, calendar: calendar)
        save()

        if target.hasTime && !target.isDone {
            // The first task with a time is when we ask to send reminders.
            Task {
                await Reminders.requestPermission()
                Reminders.sync(target)
            }
        } else {
            Reminders.sync(target)
        }
    }

    /// Ticks or unticks a task. Returns true when the task is now done.
    @discardableResult
    func toggle(_ task: TaskItem) -> Bool {
        let result = TaskActions.toggle(task, in: context, calendar: calendar)
        save()
        Reminders.sync(task)
        if let next = result.nextOccurrence {
            Reminders.sync(next)
        }
        if !result.removedIDs.isEmpty {
            Reminders.remove(ids: result.removedIDs)
        }
        if result.isDone {
            celebrateIfTodayIsDone(after: task)
        }
        return result.isDone
    }

    func delete(_ task: TaskItem) {
        let id = task.id
        context.delete(task)
        save()
        Reminders.remove(ids: [id])
    }

    func moveToTomorrow(_ task: TaskItem) {
        TaskActions.moveToTomorrow(task, calendar: calendar)
        save()
        Reminders.sync(task)
    }

    func duplicate(_ task: TaskItem) {
        let copy = TaskActions.duplicate(task, in: context)
        save()
        Reminders.sync(copy)
    }

    func setPriority(_ priority: Priority, for task: TaskItem) {
        task.priority = priority
        save()
    }

    private func celebrateIfTodayIsDone(after task: TaskItem) {
        let calendar = calendar
        guard UserDefaults.tik.bool(forKey: PrefKey.celebration),
              TaskFilter.isOnToday(task, now: .now, calendar: calendar),
              TaskQueries.openTodayCount(in: context, calendar: calendar) == 0 else { return }
        celebrations += 1
        Feedback.celebrate()
    }

    // MARK: - Lists

    func saveList(_ list: TaskList?, name: String, symbol: String, color: AccentChoice) {
        if let list {
            list.name = name
            list.symbol = symbol
            list.colorName = color.rawValue
        } else {
            let count = (try? context.fetchCount(FetchDescriptor<TaskList>())) ?? 0
            context.insert(TaskList(name: name, symbol: symbol, colorName: color.rawValue, sortIndex: count))
        }
        save()
    }

    /// Deletes a list and every task in it.
    func deleteList(_ list: TaskList) {
        let ids = list.tasks.map(\.id)
        context.delete(list)
        save()
        Reminders.remove(ids: ids)
    }

    func reorderLists(_ lists: [TaskList]) {
        for (index, list) in lists.enumerated() {
            list.sortIndex = index
        }
        save()
    }

    // MARK: - Links

    /// Links from the widget: tik://today and tik://new.
    func handle(_ url: URL) {
        guard url.scheme == "tik" else { return }
        selectedTab = .today
        if url.host() == "new" {
            pendingQuickAdd = true
        }
    }

    // MARK: - Reminders

    /// Runs a button tapped on a reminder, or opens Today when the reminder
    /// itself was tapped.
    func handleReminder(action: String, taskID: String) {
        guard action == Reminders.doneActionID else {
            selectedTab = .today
            return
        }
        guard let id = UUID(uuidString: taskID),
              let task = TaskQueries.task(withID: id, in: context),
              !task.isDone else { return }
        toggle(task)
    }

    /// Schedules every open task again, after a reminder setting changed.
    func refreshReminders() {
        Reminders.resyncAll(TaskQueries.openTasks(in: context))
        updateBadge()
    }

    // MARK: - Changes made by the widget

    /// Starts a fresh context if the widget changed tasks since last time,
    /// so every screen shows the latest state.
    func reloadIfChangedElsewhere() {
        let stamp = UserDefaults.tik.double(forKey: PrefKey.externalChange)
        guard stamp != lastExternalChange else { return }
        lastExternalChange = stamp

        let fresh = ModelContext(container)
        fresh.autosaveEnabled = true
        context = fresh
        contextID = UUID()
    }

    // MARK: - First launch

    private func createStarterListsIfNeeded() {
        let defaults = UserDefaults.tik
        guard !defaults.bool(forKey: PrefKey.didCreateStarterLists) else { return }
        defaults.set(true, forKey: PrefKey.didCreateStarterLists)

        guard ((try? context.fetchCount(FetchDescriptor<TaskList>())) ?? 0) == 0 else { return }
        let language = preferences.language
        context.insert(TaskList(name: L10n.string("Personal", language), symbol: "house.fill", colorName: "blue", sortIndex: 0))
        context.insert(TaskList(name: L10n.string("Work", language), symbol: "briefcase.fill", colorName: "orange", sortIndex: 1))
        try? context.save()
    }
}
