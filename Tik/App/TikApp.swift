import SwiftUI

@main
struct TikApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel.shared

    init() {
        #if DEBUG
        DemoData.applyLaunchArguments(to: AppModel.shared)
        #endif
        Vazirmatn.applyToNavigationBars(for: Preferences.current().language)
    }

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(model)
                .modelContainer(model.container)
        }
    }
}
