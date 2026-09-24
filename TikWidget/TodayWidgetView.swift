import AppIntents
import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    let entry: TodayEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .environment(\.appLanguage, entry.preferences.language)
            .environment(\.dateFormatting, entry.formatting)
            .environment(\.accent, entry.preferences.accent)
            .environment(\.locale, entry.formatting.locale)
            .environment(\.layoutDirection, entry.preferences.language.layoutDirection)
            .tint(entry.preferences.accent.color)
            .widgetURL(URL(string: "tik://today"))
            .containerBackground(for: .widget) {
                background
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            SmallTodayView(entry: entry)
        case .systemLarge:
            TaskListWidgetView(entry: entry, limit: 8, isLarge: true)
        case .accessoryCircular:
            CircularTodayView(entry: entry)
        case .accessoryRectangular:
            RectangularTodayView(entry: entry)
        case .accessoryInline:
            InlineTodayView(entry: entry)
        default:
            TaskListWidgetView(entry: entry, limit: 3, isLarge: false)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch family {
        case .accessoryCircular:
            AccessoryWidgetBackground()
        case .accessoryRectangular, .accessoryInline:
            Color.clear
        default:
            ZStack {
                Color(uiColor: .systemBackground)
                LinearGradient(colors: [entry.preferences.accent.color.opacity(0.22),
                                        entry.preferences.accent.partner.opacity(0.12),
                                        .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

// MARK: - Home Screen

/// The date, "Today", how many are done, and a + button.
private struct WidgetHeader: View {
    enum Style {
        /// Two lines: the full date above a big "Today". For the large widget.
        case full
        /// One line: "Today" and a short date side by side. For the medium widget.
        case inline
        /// Two small lines and no + button. For the small widget.
        case compact
    }

    let entry: TodayEntry
    var style: Style = .full

    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if style == .inline {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Today")
                        .tikFont(size: 17, weight: .bold, design: .rounded)
                    date(entry.formatting.shortDay(entry.date))
                }
                .lineLimit(1)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    date(style == .compact ? entry.formatting.shortDay(entry.date) : entry.formatting.fullDay(entry.date))
                    Text("Today")
                        .tikFont(size: style == .compact ? 17 : 20, weight: .bold, design: .rounded)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if entry.totalCount > 0 {
                Text(verbatim: "\(entry.doneCount)/\(entry.totalCount)")
                    .tikFont(size: 13, weight: .semibold, design: .rounded)
                    .foregroundStyle(.secondary)
            }

            if style != .compact {
                Link(destination: URL(string: "tik://new")!) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(.tint, in: .circle)
                }
                .accessibilityLabel(Text("New Task"))
            }
        }
    }

    private func date(_ text: String) -> some View {
        Text(text)
            .tikFont(size: 11, weight: .semibold)
            .textCase(language == .english ? .uppercase : nil)
            .foregroundStyle(.tint)
            .lineLimit(1)
    }
}

/// One task with a check circle that works right inside the widget.
private struct WidgetTaskRow: View {
    let task: WidgetTask
    var compact = false

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: ToggleTaskIntent(taskID: task.id)) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: compact ? 15 : 17, weight: .medium))
                    .foregroundStyle(checkStyle)
                    .contentTransition(.symbolEffect(.replace))
                    .invalidatableContent()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? Text("Mark as Not Done") : Text("Mark as Done"))

            Text(task.title)
                .tikFont(size: compact ? 12 : 14, weight: .medium)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
                .lineLimit(1)

            Spacer(minLength: 4)

            if !task.isDone, let time = task.time {
                Text(verbatim: time)
                    .tikFont(size: 11, weight: .medium)
                    .foregroundStyle(task.isLate ? Color.red : Color.secondary)
            } else if !task.isDone, task.priority != .none {
                Text(verbatim: task.priority.marks)
                    .tikFont(size: 12, weight: .heavy)
                    .foregroundStyle(task.priority.color)
            }
        }
    }

    private var checkStyle: AnyShapeStyle {
        if task.isDone {
            return AnyShapeStyle(.tint)
        }
        return AnyShapeStyle(task.priority == .none ? Color.secondary : task.priority.color)
    }
}

private struct WidgetEmptyState: View {
    let entry: TodayEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.totalCount > 0 ? "checkmark.seal.fill" : "sun.max.fill")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.tint)
            Text(entry.totalCount > 0 ? LocalizedStringKey("All done") : "No tasks today")
                .tikFont(size: 13, weight: .semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Medium and large: a header and a list of tasks.
private struct TaskListWidgetView: View {
    let entry: TodayEntry
    let limit: Int
    let isLarge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 10 : 9) {
            WidgetHeader(entry: entry, style: isLarge ? .full : .inline)

            if isLarge && entry.totalCount > 0 {
                ProgressBar(value: entry.progress, height: 8)
            }

            if entry.tasks.isEmpty {
                WidgetEmptyState(entry: entry)
            } else {
                VStack(alignment: .leading, spacing: isLarge ? 10 : 8) {
                    ForEach(entry.tasks.prefix(limit)) { task in
                        WidgetTaskRow(task: task)
                    }
                }
                if isLarge && entry.tasks.count > limit {
                    Text("+\(entry.tasks.count - limit) more")
                        .tikFont(size: 11, weight: .medium)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

/// Small: the next few tasks and a thin progress bar.
private struct SmallTodayView: View {
    let entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            WidgetHeader(entry: entry, style: .compact)

            let open = entry.tasks.filter { !$0.isDone }
            if open.isEmpty {
                WidgetEmptyState(entry: entry)
            } else {
                ForEach(open.prefix(3)) { task in
                    WidgetTaskRow(task: task, compact: true)
                }
                Spacer(minLength: 0)
            }

            if entry.totalCount > 0 {
                ProgressBar(value: entry.progress, height: 6)
            }
        }
    }
}

// MARK: - Lock Screen

private struct CircularTodayView: View {
    let entry: TodayEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            if entry.totalCount > 0 && entry.openCount == 0 {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
            } else {
                Text(verbatim: "\(entry.openCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }
}

private struct RectangularTodayView: View {
    let entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                if entry.openCount == 0 {
                    Text("All done")
                } else {
                    Text("\(entry.openCount) left")
                }
            } icon: {
                Image(systemName: "checklist")
            }
            .tikFont(size: 14, weight: .bold)
            .widgetAccentable()

            ForEach(entry.tasks.filter { !$0.isDone }.prefix(2)) { task in
                Text(task.title)
                    .tikFont(size: 13)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InlineTodayView: View {
    let entry: TodayEntry

    var body: some View {
        Label {
            if entry.openCount == 0 {
                Text("All done today")
            } else {
                Text("\(entry.openCount) tasks left today")
            }
        } icon: {
            Image(systemName: "checkmark.circle")
        }
    }
}
