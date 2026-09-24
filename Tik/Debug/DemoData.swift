#if DEBUG
import Foundation
import SwiftData

/// Example content for screenshots and quick testing. Debug builds only.
///
/// Launch arguments:
/// - `-demo`: replace all data with example tasks
/// - `-lang en|fa`, `-theme system|light|dark`, `-accent blue|purple|…`,
///   `-calendar persian|gregorian`: change settings
/// - `-tab today|lists|search`: open on a tab
enum DemoData {
    @MainActor
    static func applyLaunchArguments(to model: AppModel) {
        let arguments = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }

        let defaults = UserDefaults.tik
        if arguments.contains("-demo") {
            // Start from the default settings, so every run looks the same.
            for key in defaults.dictionaryRepresentation().keys where key != PrefKey.didCreateStarterLists {
                defaults.removeObject(forKey: key)
            }
        }
        if let language = value(after: "-lang") { defaults.set(language, forKey: PrefKey.language) }
        if let theme = value(after: "-theme") { defaults.set(theme, forKey: PrefKey.theme) }
        if let accent = value(after: "-accent") { defaults.set(accent, forKey: PrefKey.accent) }
        if let calendar = value(after: "-calendar") { defaults.set(calendar, forKey: PrefKey.calendar) }

        switch value(after: "-tab") {
        case "lists": model.selectedTab = .lists
        case "search": model.selectedTab = .search
        default: break
        }

        if arguments.contains("-demo") {
            fill(model.context, language: model.preferences.language, calendar: model.calendar)
        }
    }

    static func fill(_ context: ModelContext, language: AppLanguage, calendar: Calendar, now: Date = .now) {
        for task in (try? context.fetch(FetchDescriptor<TaskItem>())) ?? [] {
            context.delete(task)
        }
        for list in (try? context.fetch(FetchDescriptor<TaskList>())) ?? [] {
            context.delete(list)
        }

        let text = language == .farsi ? Texts.farsi : Texts.english
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: today)!
        }
        func at(_ offset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day(offset))!
        }

        func list(_ name: String, _ symbol: String, _ color: String, _ index: Int) -> TaskList {
            let list = TaskList(name: name, symbol: symbol, colorName: color, sortIndex: index)
            context.insert(list)
            return list
        }

        func task(_ title: String, due: Date? = nil, hasTime: Bool = false, list: TaskList? = nil,
                  priority: Priority = .none, repeats: RepeatRule? = nil, doneAt: Date? = nil,
                  note: String = "", subtasks: [(String, Bool)] = []) {
            let task = TaskItem(title: title, dueDate: due, hasTime: hasTime, priority: priority)
            task.note = note
            task.repeatRule = repeats
            if let doneAt {
                task.isDone = true
                task.completedAt = doneAt
            }
            context.insert(task)
            task.list = list
            for (index, subtask) in subtasks.enumerated() {
                let item = Subtask(title: subtask.0, isDone: subtask.1, sortIndex: index)
                context.insert(item)
                item.task = task
            }
        }

        let personal = list(text.personal, "house.fill", "blue", 0)
        let work = list(text.work, "briefcase.fill", "orange", 1)
        let shopping = list(text.shopping, "cart.fill", "green", 2)
        let health = list(text.health, "heart.fill", "pink", 3)

        task(text.run, due: at(0, 7), hasTime: true, list: health,
             repeats: RepeatRule(frequency: .daily), doneAt: at(0, 7, 40))
        task(text.email, due: at(0, 10), hasTime: true, list: work, priority: .high)
        task(text.callMom, due: day(0), list: personal, priority: .medium)
        task(text.groceries, due: day(0), list: shopping,
             subtasks: [(text.milk, true), (text.bread, false), (text.eggs, false)])
        task(text.read, due: at(0, 21, 30), hasTime: true, list: personal,
             repeats: RepeatRule(frequency: .daily))
        task(text.plants, due: day(0), list: personal, doneAt: at(0, 9, 10))
        task(text.bill, due: day(-1), list: personal, priority: .high)

        task(text.meeting, due: at(1, 11), hasTime: true, list: work, note: text.meetingNote)
        task(text.gym, due: at(1, 18), hasTime: true, list: health,
             repeats: RepeatRule(frequency: .weekdays, weekdays: [7, 2, 4]))
        task(text.dentist, due: at(3, 16, 30), hasTime: true, list: health)
        task(text.trip, due: day(6), list: personal)

        task(text.learn)
        task(text.desk)
        task(text.portfolio, due: day(-1), list: work, doneAt: at(-1, 20))

        try? context.save()
    }

    private struct Texts {
        var personal, work, shopping, health: String
        var run, email, callMom, groceries, milk, bread, eggs, read, plants, bill: String
        var meeting, meetingNote, gym, dentist, trip, learn, desk, portfolio: String

        static let english = Texts(
            personal: "Personal", work: "Work", shopping: "Shopping", health: "Health",
            run: "Morning run", email: "Reply to Sara's email", callMom: "Call mom",
            groceries: "Buy groceries", milk: "Milk", bread: "Bread", eggs: "Eggs",
            read: "Read 20 pages", plants: "Water the plants", bill: "Pay the internet bill",
            meeting: "Team meeting", meetingNote: "Bring the new designs.",
            gym: "Gym", dentist: "Dentist appointment", trip: "Plan the weekend trip",
            learn: "Learn SwiftData", desk: "Clean the desk", portfolio: "Finish the portfolio site"
        )

        static let farsi = Texts(
            personal: "شخصی", work: "کاری", shopping: "خرید", health: "سلامتی",
            run: "دویدن صبحگاهی", email: "جواب ایمیل سارا", callMom: "تماس با مامان",
            groceries: "خرید خانه", milk: "شیر", bread: "نان", eggs: "تخم\u{200C}مرغ",
            read: "خواندن 20 صفحه کتاب", plants: "آب دادن به گلدان\u{200C}ها", bill: "پرداخت قبض اینترنت",
            meeting: "جلسه\u{200C}ی تیم", meetingNote: "طرح\u{200C}های جدید را بیاور.",
            gym: "باشگاه", dentist: "وقت دندان\u{200C}پزشکی", trip: "برنامه\u{200C}ریزی سفر آخر هفته",
            learn: "یادگیری SwiftData", desk: "مرتب کردن میز", portfolio: "تمام کردن سایت نمونه\u{200C}کار"
        )
    }
}
#endif
