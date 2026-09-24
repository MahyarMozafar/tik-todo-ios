import Foundation
import SwiftData

/// Where Tik keeps its data.
///
/// The database lives in the App Group folder, so the widget can read the
/// same tasks and tick them. If the App Group is missing (for example when
/// the capability was removed while signing), it falls back to the app's own
/// folder: the app still works, only the widget can't see the tasks.
enum SharedStore {
    static let appGroupID = "group.com.mahyarmozafar.tik"

    static let schema = Schema([TaskItem.self, TaskList.self, Subtask.self])

    static var storeURL: URL {
        let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "Tik.store")
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
