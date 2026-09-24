import SwiftUI

extension View {
    /// Tap to edit, swipe to tick, delete or move to tomorrow, and a long-press
    /// menu with more.
    func taskActions(for task: TaskItem, onEdit: @escaping () -> Void) -> some View {
        modifier(TaskActionsModifier(task: task, onEdit: onEdit))
    }
}

private struct TaskActionsModifier: ViewModifier {
    @Environment(AppModel.self) private var model

    let task: TaskItem
    var onEdit: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            .onTapGesture(perform: onEdit)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(action: toggle) {
                    if task.isDone {
                        Label("Not Done", systemImage: "arrow.uturn.backward")
                    } else {
                        Label("Done", systemImage: "checkmark")
                    }
                }
                .tint(.green)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: delete) {
                    Label("Delete", systemImage: "trash")
                }
                if !task.isDone {
                    Button(action: moveToTomorrow) {
                        Label("Tomorrow", systemImage: "sunrise")
                    }
                    .tint(.orange)
                }
            }
            .contextMenu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(action: toggle) {
                    if task.isDone {
                        Label("Mark as Not Done", systemImage: "arrow.uturn.backward")
                    } else {
                        Label("Mark as Done", systemImage: "checkmark.circle")
                    }
                }
                if !task.isDone {
                    Button(action: moveToTomorrow) {
                        Label("Move to Tomorrow", systemImage: "sunrise")
                    }
                }
                Menu {
                    Picker("Priority", selection: priority) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                } label: {
                    Label("Priority", systemImage: "exclamationmark.circle")
                }
                Button {
                    withAnimation(.snappy) { model.duplicate(task) }
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Divider()
                Button(role: .destructive, action: delete) {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    private var priority: Binding<Priority> {
        Binding(
            get: { task.priority },
            set: { model.setPriority($0, for: task) }
        )
    }

    private func toggle() {
        withAnimation(.snappy) { _ = model.toggle(task) }
    }

    private func moveToTomorrow() {
        withAnimation(.snappy) { model.moveToTomorrow(task) }
    }

    private func delete() {
        withAnimation(.snappy) { model.delete(task) }
    }
}
