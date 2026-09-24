import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        TabView(selection: $model.selectedTab) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                NavigationStack {
                    TodayView()
                }
            }
            Tab("Lists", systemImage: "square.stack", value: AppTab.lists) {
                ListsTab()
            }
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                NavigationStack {
                    SearchView()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
