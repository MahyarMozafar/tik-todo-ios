import SwiftUI

/// One task, drawn as a glass card: the check circle, the title, and a line
/// of small details (time, list, subtasks...).
struct TaskRow: View {
    let task: TaskItem
    /// Show the day (like "Tomorrow"), not only the time. Off on Today.
    var showsDay = true
    /// Show which list the task is in. Off inside that list.
    var showsList = true
    var onToggle: () -> Void

    @Environment(\.dateFormatting) private var formatting
    @Environment(\.calendar) private var calendar

    @AppStorage(PrefKey.fieldNotes, store: .tik) private var notesEnabled = true
    @AppStorage(PrefKey.fieldSubtasks, store: .tik) private var subtasksEnabled = true
    @AppStorage(PrefKey.fieldDates, store: .tik) private var datesEnabled = true
    @AppStorage(PrefKey.fieldRepeat, store: .tik) private var repeatEnabled = true
    @AppStorage(PrefKey.fieldPriority, store: .tik) private var priorityEnabled = true
    @AppStorage(PrefKey.fieldPhotos, store: .tik) private var photosEnabled = true

    /// The tick shows right away. The real change comes a moment later, so
    /// the check animation can play before the task moves down the list.
    @State private var pendingDone: Bool?
    @State private var pendingChange: Task<Void, Never>?

    private var isDone: Bool { pendingDone ?? task.isDone }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: tapCheck) {
                CheckCircle(isDone: isDone, ringColor: ringColor)
                    .padding(10)
                    .contentShape(.rect)
                    .padding(-10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? Text("Mark as Not Done") : Text("Mark as Done"))
            .accessibilityIdentifier("check-\(task.title)")

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .tikFont(.body, weight: .medium)
                    .strikethrough(isDone, color: .secondary)
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("taskTitle")

                if hasDetails {
                    details
                }
            }

            if showsPriority {
                Text(task.priority.marks)
                    .tikFont(.subheadline, weight: .heavy)
                    .foregroundStyle(task.priority.color)
                    .accessibilityLabel(Text(task.priority.title))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .opacity(isDone ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.2), value: isDone)
    }

    // MARK: - Details line

    private var details: some View {
        HStack(spacing: 10) {
            if showsDue, let due = task.dueDate {
                dueLabel(due)
            }
            if showsRepeat {
                Image(systemName: "repeat")
                    .accessibilityLabel(Text("Repeats"))
            }
            if showsList, let list = task.list {
                HStack(spacing: 4) {
                    Circle()
                        .fill(list.color.color)
                        .frame(width: 7, height: 7)
                    Text(list.name)
                }
            }
            if showsSubtasks {
                HStack(spacing: 3) {
                    Image(systemName: "checklist")
                    Text(verbatim: "\(task.doneSubtaskCount)/\(task.subtasks.count)")
                }
            }
            if showsNote {
                Image(systemName: "text.alignleft")
                    .accessibilityLabel(Text("Notes"))
            }
            if showsPhoto {
                Image(systemName: "photo")
                    .accessibilityLabel(Text("Photo"))
            }
        }
        .tikFont(.caption, weight: .medium)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private func dueLabel(_ due: Date) -> some View {
        let overdue = TaskFilter.isOverdue(task, now: .now, calendar: calendar)
        let day = (showsDay || overdue) ? formatting.relativeDay(due) : nil
        let time = task.hasTime ? formatting.time(due) : nil
        let isLate = !task.isDone && (overdue || (task.hasTime && due < .now))

        return Label([day, time].compactMap { $0 }.joined(separator: " \u{00B7} "),
                     systemImage: task.hasTime ? "clock" : "calendar")
            .foregroundStyle(isLate ? Color.red : Color.secondary)
    }

    // MARK: - What to show

    private var showsDue: Bool {
        guard datesEnabled, task.dueDate != nil else { return false }
        return showsDay || task.hasTime || TaskFilter.isOverdue(task, now: .now, calendar: calendar)
    }

    private var showsRepeat: Bool { repeatEnabled && task.repeatRuleJSON != nil }
    private var showsSubtasks: Bool { subtasksEnabled && !task.subtasks.isEmpty }
    private var showsNote: Bool { notesEnabled && !task.note.isEmpty }
    private var showsPhoto: Bool { photosEnabled && task.hasPhoto }
    private var showsPriority: Bool { priorityEnabled && task.priority != .none && !isDone }

    private var hasDetails: Bool {
        showsDue || showsRepeat || (showsList && task.list != nil) || showsSubtasks || showsNote || showsPhoto
    }

    private var ringColor: Color {
        priorityEnabled && task.priority != .none ? task.priority.color : .secondary
    }

    // MARK: - Ticking

    private func tapCheck() {
        let target = !isDone
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            pendingDone = target
        }
        pendingChange?.cancel()
        pendingChange = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            if task.isDone != target {
                onToggle()
            }
            pendingDone = nil
        }
    }
}
