import Combine
import SwiftData
import SwiftUI

/// The first screen: today's tasks, late tasks, and a progress bar.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: #Predicate<TaskItem> { $0.dueDate != nil })
    private var datedTasks: [TaskItem]

    @AppStorage(PrefKey.sortOrder, store: .tik) private var sortOrder: TaskSortOrder = .time
    @AppStorage(PrefKey.showProgress, store: .tik) private var showProgress = true
    @AppStorage(PrefKey.showCompletedInToday, store: .tik) private var showCompleted = true

    @State private var now = Date.now
    @State private var isAdding = false
    @State private var editing: EditorRequest?
    @State private var showSettings = false

    var body: some View {
        let todays = TaskFilter.today(datedTasks, now: now, calendar: calendar, order: sortOrder)
        let visible = showCompleted ? todays : todays.filter { !$0.isDone }
        let doneCount = todays.filter(\.isDone).count

        List {
            if showProgress && !todays.isEmpty {
                ProgressCard(done: doneCount, total: todays.count)
                    .cardRow(top: 4, bottom: 12)
            }

            if visible.isEmpty {
                TodayEmptyState(allDone: !todays.isEmpty)
                    .cardRow()
            } else {
                ForEach(visible) { task in
                    TaskRow(task: task, showsDay: false) {
                        withAnimation(.snappy) { _ = model.toggle(task) }
                    }
                    .taskActions(for: task) { editing = .edit(task) }
                    .cardRow()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaBar(edge: .top) {
            TodayHeader(date: now) {
                showSettings = true
            }
        }
        .safeAreaBar(edge: .bottom) {
            QuickAddBar(isExpanded: $isAdding) { title in
                withAnimation(.snappy) {
                    _ = model.addTask(title: title, dueDate: calendar.startOfDay(for: .now))
                }
            } onShowDetails: { title in
                editing = .new(title: title, dueDate: calendar.startOfDay(for: .now))
            }
        }
        .background { AppBackground() }
        .overlay {
            ConfettiView(trigger: model.celebrations)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editing) { request in
            TaskEditorView(request: request)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            now = .now
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                now = .now
            }
        }
        .onChange(of: model.pendingQuickAdd, initial: true) { _, pending in
            guard pending else { return }
            model.pendingQuickAdd = false
            isAdding = true
        }
    }
}
