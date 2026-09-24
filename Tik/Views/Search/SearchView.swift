import SwiftData
import SwiftUI

enum SearchScope: Hashable, CaseIterable {
    case all
    case open
    case done

    var title: LocalizedStringKey {
        switch self {
        case .all: "All"
        case .open: "Open"
        case .done: "Done"
        }
    }
}

/// The Search tab on iPhone.
struct SearchView: View {
    @State private var query = ""
    @State private var scope: SearchScope = .all

    var body: some View {
        SearchResults(query: query, scope: scope)
            .navigationTitle(Text("Search"))
            .searchable(text: $query, prompt: Text("Tasks, notes and subtasks"))
            .searchScopes($scope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.title).tag(scope)
                }
            }
    }
}

/// Finds tasks by title, notes or subtasks, in every list.
/// Used by the Search tab on iPhone and the sidebar search on iPad.
struct SearchResults: View {
    let query: String
    let scope: SearchScope

    @Environment(AppModel.self) private var model
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]

    @State private var editing: EditorRequest?

    var body: some View {
        let results = results

        List {
            ForEach(results) { task in
                TaskRow(task: task) {
                    withAnimation(.snappy) { _ = model.toggle(task) }
                }
                .taskActions(for: task) { editing = .edit(task) }
                .cardRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .overlay {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                EmptyStateView(symbol: "magnifyingglass",
                               title: Text("Search your tasks"),
                               message: Text("Find any task by its title, notes or subtasks."))
            } else if results.isEmpty {
                EmptyStateView(symbol: "text.page.slash",
                               title: Text("No results"),
                               message: Text("Nothing matches \u{201C}\(query)\u{201D}."))
            }
        }
        .readableWidth()
        .background { AppBackground() }
        .sheet(item: $editing) { request in
            TaskEditorView(request: request)
        }
    }

    /// Matching tasks, open ones first.
    private var results: [TaskItem] {
        let matches = tasks.filter { task in
            guard TaskFilter.matches(task, query: query) else { return false }
            switch scope {
            case .all: return true
            case .open: return !task.isDone
            case .done: return task.isDone
            }
        }
        return matches.filter { !$0.isDone } + matches.filter(\.isDone)
    }
}
