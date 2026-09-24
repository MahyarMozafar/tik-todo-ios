import SwiftData
import SwiftUI

/// The tasks in one list, or in a smart list like Scheduled.
struct ListDetailView: View {
    let selection: ListSelection

    @Environment(AppModel.self) private var model
    @Environment(\.calendar) private var calendar
    @Environment(\.dateFormatting) private var formatting
    @Environment(\.accent) private var accent
    @Environment(\.dismiss) private var dismiss

    @Query private var tasks: [TaskItem]
    @AppStorage(PrefKey.sortOrder, store: .tik) private var sortOrder: TaskSortOrder = .time

    @State private var showCompleted = false
    @State private var isAdding = false
    @State private var editing: EditorRequest?
    @State private var editingList: ListEditorRequest?
    @State private var confirmDeleteList = false

    var body: some View {
        List {
            switch selection {
            case .smart(.scheduled):
                scheduledContent
            case .smart(.completed):
                completedContent
            default:
                listContent
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { AppBackground() }
        .navigationTitle(title)
        .toolbar { toolbar }
        .tint(tint)
        .safeAreaBar(edge: .bottom) {
            if canAdd {
                QuickAddBar(isExpanded: $isAdding) { title in
                    withAnimation(.snappy) {
                        _ = model.addTask(title: title, dueDate: newTaskDefaults.dueDate, list: newTaskDefaults.list)
                    }
                } onShowDetails: { title in
                    editing = .new(title: title, dueDate: newTaskDefaults.dueDate, list: newTaskDefaults.list)
                }
            }
        }
        .sheet(item: $editing) { request in
            TaskEditorView(request: request)
        }
        .sheet(item: $editingList) { request in
            ListEditorView(request: request)
        }
        .confirmationDialog(Text("Delete this list?"), isPresented: $confirmDeleteList, titleVisibility: .visible) {
            Button("Delete List", role: .destructive, action: deleteList)
        } message: {
            Text("All tasks in this list will be deleted too.")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var listContent: some View {
        let scoped = scopedTasks
        let open = TaskFilter.sorted(scoped.filter { !$0.isDone }, order: sortOrder, now: .now, calendar: calendar)
        let done = scoped.filter(\.isDone).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        if open.isEmpty && done.isEmpty {
            emptyState
        } else {
            rows(open, showsDay: selection != .smart(.today))

            if !done.isEmpty {
                Button {
                    withAnimation(.snappy) { showCompleted.toggle() }
                } label: {
                    HStack {
                        if showCompleted {
                            Text("Hide Completed")
                        } else {
                            Text("Show Completed (\(done.count))")
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showCompleted ? 180 : 0))
                    }
                    .tikFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .cardRow(top: 14, bottom: 6)

                if showCompleted {
                    rows(done, showsDay: true)
                }
            }
        }
    }

    @ViewBuilder
    private var scheduledContent: some View {
        let groups = TaskFilter.scheduled(tasks, now: .now, calendar: calendar, order: sortOrder)
        if groups.isEmpty {
            emptyState
        }
        ForEach(groups, id: \.day) { group in
            Section {
                rows(group.tasks, showsDay: false)
            } header: {
                dayHeader(formatting.relativeDay(group.day), detail: formatting.dayAndMonth(group.day))
            }
        }
    }

    @ViewBuilder
    private var completedContent: some View {
        let groups = TaskFilter.completed(tasks, calendar: calendar)
        if groups.isEmpty {
            emptyState
        }
        ForEach(groups, id: \.day) { group in
            Section {
                rows(group.tasks, showsDay: true)
            } header: {
                dayHeader(formatting.relativeDay(group.day), detail: formatting.dayAndMonth(group.day))
            }
        }
    }

    private func rows(_ items: [TaskItem], showsDay: Bool) -> some View {
        ForEach(items) { task in
            TaskRow(task: task, showsDay: showsDay, showsList: showsListNames) {
                withAnimation(.snappy) { _ = model.toggle(task) }
            }
            .taskActions(for: task) { editing = .edit(task) }
            .cardRow()
        }
    }

    private func dayHeader(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .tikFont(.headline, weight: .bold)
                .foregroundStyle(.primary)
            if title != detail {
                Text(detail)
                    .tikFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
        .padding(.horizontal, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 84, height: 84)
                .glassEffect(.regular, in: .circle)
            Text("Nothing here yet")
                .tikFont(.title3, weight: .semibold)
            Text(selection == .smart(.completed)
                 ? LocalizedStringKey("Tasks you finish will show up here.")
                 : "Tap + to add a task.")
                .tikFont(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .cardRow()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if case .list(let list) = selection {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        editingList = ListEditorRequest(list: list)
                    } label: {
                        Label("Edit List", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmDeleteList = true
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
    }

    // MARK: - Details for each kind of list

    private var scopedTasks: [TaskItem] {
        switch selection {
        case .smart(.today):
            TaskFilter.today(tasks, now: .now, calendar: calendar, order: sortOrder)
        case .smart:
            tasks
        case .inbox:
            tasks.filter { $0.list == nil }
        case .list(let list):
            tasks.filter { $0.list?.persistentModelID == list.persistentModelID }
        }
    }

    private var title: Text {
        switch selection {
        case .smart(let smart): Text(smart.title)
        case .inbox: Text("Inbox")
        case .list(let list): Text(list.name)
        }
    }

    private var symbol: String {
        switch selection {
        case .smart(let smart): smart.symbol
        case .inbox: "tray.fill"
        case .list(let list): list.symbol
        }
    }

    private var tint: Color {
        if case .list(let list) = selection {
            return list.color.color
        }
        return accent.color
    }

    private var showsListNames: Bool {
        if case .list = selection { return false }
        return true
    }

    private var canAdd: Bool {
        selection != .smart(.completed)
    }

    /// Where a task added on this screen goes.
    private var newTaskDefaults: (dueDate: Date?, list: TaskList?) {
        let today = calendar.startOfDay(for: .now)
        switch selection {
        case .smart(.today): return (today, nil)
        case .smart(.scheduled): return (calendar.date(byAdding: .day, value: 1, to: today), nil)
        case .list(let list): return (nil, list)
        default: return (nil, nil)
        }
    }

    private func deleteList() {
        guard case .list(let list) = selection else { return }
        dismiss()
        // Leave the screen first, so it never shows a list that is gone.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation { model.deleteList(list) }
        }
    }
}
