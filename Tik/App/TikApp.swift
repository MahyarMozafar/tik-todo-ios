import SwiftUI

@main
struct TikApp: App {
    @State private var model = AppModel.shared

    init() {
        #if DEBUG
        DemoData.applyLaunchArguments(to: AppModel.shared)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(model)
                .modelContainer(model.container)
        }
    }
}
