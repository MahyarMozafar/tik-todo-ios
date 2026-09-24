import Foundation
import Testing
@testable import Tik

@MainActor
struct WidgetActionsTests {
    @Test func tickingFromTheWidgetSavesAndTellsTheApp() throws {
        let context = try makeContext()
        let task = makeTask("Call mom", due: date(2026, 9, 24), in: context)
        try context.save()

        let defaults = try #require(UserDefaults(suiteName: "WidgetActionsTests"))
        defaults.removePersistentDomain(forName: "WidgetActionsTests")

        let found = try WidgetActions.toggleTask(withID: task.id, in: context, defaults: defaults,
                                                 now: date(2026, 9, 24, 9))
        #expect(found)
        #expect(task.isDone)
        #expect(!context.hasChanges)
        #expect(defaults.double(forKey: PrefKey.externalChange) == date(2026, 9, 24, 9).timeIntervalSince1970)
    }

    @Test func unknownTaskIsIgnored() throws {
        let context = try makeContext()
        let found = try WidgetActions.toggleTask(withID: UUID(), in: context,
                                                 defaults: UserDefaults(suiteName: "WidgetActionsTests")!)
        #expect(!found)
    }
}
