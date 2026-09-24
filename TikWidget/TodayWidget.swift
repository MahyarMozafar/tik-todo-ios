import SwiftUI
import WidgetKit

@main
struct TikWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("See today's tasks and tick them off.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        .sample()
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let entry = WidgetData.todayEntry()
        completion(context.isPreview && entry.totalCount == 0 ? .sample() : entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date.now
        // One entry now, and one each time a task becomes late today.
        let dates = [now] + WidgetData.upcomingTimes(after: now)
        let entries = dates.map { WidgetData.todayEntry(at: $0) }

        // Start again from scratch after midnight, when "today" changes.
        let calendar = entries[0].formatting.calendar
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }
}
