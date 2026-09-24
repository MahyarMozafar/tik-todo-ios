import SwiftUI

/// Tabs on iPhone, a sidebar on iPad (and on any wide window).
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            SplitRootView()
        } else {
            TabRootView()
        }
    }
}

struct TabRootView: View {
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
