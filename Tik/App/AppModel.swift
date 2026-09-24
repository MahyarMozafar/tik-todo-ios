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

    /// Goes up by one when something outside a screen (like the widget's
    /// + button) asks to add a task.
    var quickAddRequests = 0

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
    }

    /// Ticks or unticks a task. Returns true when the task is now done.
    @discardableResult
    func toggle(_ task: TaskItem) -> Bool {
        let result = TaskActions.toggle(task, in: context, calendar: calendar)
        save()
        return result.isDone
    }

    func delete(_ task: TaskItem) {
        context.delete(task)
        save()
    }

    func moveToTomorrow(_ task: TaskItem) {
        TaskActions.moveToTomorrow(task, calendar: calendar)
        save()
    }

    func duplicate(_ task: TaskItem) {
        TaskActions.duplicate(task, in: context)
        save()
    }

    func setPriority(_ priority: Priority, for task: TaskItem) {
        task.priority = priority
        save()
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
