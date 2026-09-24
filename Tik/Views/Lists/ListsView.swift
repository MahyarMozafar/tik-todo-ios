import SwiftData
import SwiftUI

/// The Lists tab: four smart lists at the top, then the user's own lists.
struct ListsTab: View {
    @State private var path: [ListSelection] = []

    var body: some View {
        NavigationStack(path: $path) {
            ListsView(path: $path)
                .navigationDestination(for: ListSelection.self) { selection in
                    ListDetailView(selection: selection)
                }
        }
    }
}

struct ListsView: View {
    @Binding var path: [ListSelection]

    @Environment(AppModel.self) private var model
    @Environment(\.calendar) private var calendar

    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]
    @Query private var tasks: [TaskItem]

    @State private var editingList: ListEditorRequest?
    @State private var listToDelete: TaskList?

    var body: some View {
        List {
            Section {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(SmartList.allCases) { smart in
                        Button {
                            path.append(.smart(smart))
                        } label: {
                            SmartListCard(smart: smart, count: count(for: smart))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("smart-\(smart.rawValue)")
                    }
                }
                .cardRow(top: 4, bottom: 8)
            }

            Section {
                NavigationLink(value: ListSelection.inbox) {
                    ListRowLabel(title: Text("Inbox"), symbol: "tray.fill", color: .gray,
                                 count: tasks.filter { $0.list == nil && !$0.isDone }.count)
                }
                .listRowBackground(Rectangle().fill(.regularMaterial))

                ForEach(lists) { list in
                    NavigationLink(value: ListSelection.list(list)) {
                        ListRowLabel(title: Text(list.name), symbol: list.symbol, color: list.color.color,
                                     count: list.openTaskCount)
                    }
                    .listRowBackground(Rectangle().fill(.regularMaterial))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            listToDelete = list
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingList = ListEditorRequest(list: list)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.gray)
                    }
                    .contextMenu {
                        Button {
                            editingList = ListEditorRequest(list: list)
                        } label: {
                            Label("Edit List", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            listToDelete = list
                        } label: {
                            Label("Delete List", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveLists)
            } header: {
                Text("My Lists")
                    .tikFont(.title3, weight: .bold)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background { AppBackground() }
        .navigationTitle(Text("Lists"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingList = ListEditorRequest(list: nil)
                } label: {
                    Label("New List", systemImage: "plus")
                }
                .accessibilityIdentifier("newListButton")
            }
        }
        .sheet(item: $editingList) { request in
            ListEditorView(request: request)
        }
        .confirmationDialog(
            Text("Delete \u{201C}\(listToDelete?.name ?? "")\u{201D}?"),
            isPresented: Binding(get: { listToDelete != nil }, set: { if !$0 { listToDelete = nil } }),
            titleVisibility: .visible,
            presenting: listToDelete
        ) { list in
            Button("Delete List", role: .destructive) {
                withAnimation { model.deleteList(list) }
            }
        } message: { _ in
            Text("All tasks in this list will be deleted too.")
        }
    }

    private func count(for smart: SmartList) -> Int {
        let now = Date.now
        switch smart {
        case .today:
            return TaskFilter.today(tasks, now: now, calendar: calendar, order: .time).filter { !$0.isDone }.count
        case .scheduled:
            return TaskFilter.scheduled(tasks, now: now, calendar: calendar, order: .time).reduce(0) { $0 + $1.tasks.count }
        case .all:
            return tasks.filter { !$0.isDone }.count
        case .completed:
            return tasks.filter(\.isDone).count
        }
    }

    private func moveLists(from source: IndexSet, to destination: Int) {
        var reordered = lists
        reordered.move(fromOffsets: source, toOffset: destination)
        model.reorderLists(reordered)
    }
}

/// A glass card for a smart list: icon, count and name.
struct SmartListCard: View {
    let smart: SmartList
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: smart.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(smart.color.gradient, in: .circle)
                Spacer()
                Text(count, format: .number)
                    .tikFont(.title, weight: .bold, design: .rounded)
                    .contentTransition(.numericText(value: Double(count)))
            }
            Text(smart.title)
                .tikFont(.subheadline, weight: .semibold)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

/// A row in "My Lists": colored icon, name and number of open tasks.
struct ListRowLabel: View {
    let title: Text
    let symbol: String
    let color: Color
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color.gradient, in: .circle)
            title
                .tikFont(.body, weight: .medium)
            Spacer()
            if count > 0 {
                Text(count, format: .number)
                    .tikFont(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
