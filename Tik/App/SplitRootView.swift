import SwiftData
import SwiftUI

/// The iPad layout: a sidebar with Today, the smart lists and your own
/// lists, and the chosen one on the right. Search lives in the sidebar.
struct SplitRootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.calendar) private var calendar

    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]
    @Query private var tasks: [TaskItem]

    @State private var selection: SidebarItem? = .today
    @State private var query = ""
    @State private var editingList: ListEditorRequest?

    enum SidebarItem: Hashable {
        case today
        case place(ListSelection)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    row(.today, title: Text("Today"), symbol: "sun.max.fill", color: .orange, count: todayCount)
                    ForEach([SmartList.scheduled, .all, .completed]) { smart in
                        row(.place(.smart(smart)), title: Text(smart.title), symbol: smart.symbol, color: smart.color, count: 0)
                    }
                }

                Section {
                    row(.place(.inbox), title: Text("Inbox"), symbol: "tray.fill", color: .gray,
                        count: tasks.filter { $0.list == nil && !$0.isDone }.count)
                    ForEach(lists) { list in
                        row(.place(.list(list)), title: Text(list.name), symbol: list.symbol,
                            color: list.color.color, count: list.openTaskCount)
                            .contextMenu {
                                Button {
                                    editingList = ListEditorRequest(list: list)
                                } label: {
                                    Label("Edit List", systemImage: "pencil")
                                }
                            }
                    }
                } header: {
                    Text("My Lists")
                }
            }
            .navigationTitle(Text(verbatim: "Tik"))
            .searchable(text: $query, placement: .sidebar, prompt: Text("Tasks, notes and subtasks"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        model.showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingList = ListEditorRequest(list: nil)
                    } label: {
                        Label("New List", systemImage: "plus")
                    }
                }
            }
        } detail: {
            NavigationStack {
                detail
            }
        }
        .sheet(item: $editingList) { request in
            ListEditorView(request: request)
        }
        .onChange(of: model.pendingQuickAdd) { _, pending in
            if pending {
                query = ""
                selection = .today
            }
        }
        .onChange(of: lists) {
            // Go back to Today if the open list was deleted.
            if case .place(.list(let list)) = selection, !lists.contains(list) {
                selection = .today
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            SearchResults(query: query, scope: .all)
                .navigationTitle(Text("Search"))
        } else {
            switch selection {
            case .place(.list(let list)) where list.isDeleted:
                TodayView()
            case .place(let place):
                ListDetailView(selection: place)
                    .id(place)
            case .today, nil:
                TodayView()
            }
        }
    }

    private var todayCount: Int {
        TaskFilter.today(tasks, now: .now, calendar: calendar, order: .time).filter { !$0.isDone }.count
    }

    private func row(_ item: SidebarItem, title: Text, symbol: String, color: Color, count: Int) -> some View {
        NavigationLink(value: item) {
            ListRowLabel(title: title, symbol: symbol, color: color, count: count)
        }
    }
}
