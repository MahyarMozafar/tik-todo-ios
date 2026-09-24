import SwiftUI

struct ListEditorRequest: Identifiable {
    let id = UUID()
    /// The list to edit, or nil for a new list.
    var list: TaskList?
}

/// Name, color and icon for a list.
struct ListEditorView: View {
    let request: ListEditorRequest

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var symbol: String
    @State private var color: AccentChoice
    @FocusState private var nameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    init(request: ListEditorRequest) {
        self.request = request
        _name = State(initialValue: request.list?.name ?? "")
        _symbol = State(initialValue: request.list?.symbol ?? "list.bullet")
        _color = State(initialValue: request.list?.color ?? .blue)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: symbol)
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 88, height: 88)
                            .background(color.color.gradient, in: .circle)
                            .shadow(color: color.color.opacity(0.35), radius: 12, y: 6)
                            .contentTransition(.symbolEffect(.replace))

                        TextField("List Name", text: $name)
                            .tikFont(.title3, weight: .semibold)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .background(.fill.tertiary, in: .rect(cornerRadius: 14))
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .accessibilityIdentifier("listNameField")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AccentChoice.allCases) { choice in
                            Button {
                                withAnimation(.snappy) { color = choice }
                            } label: {
                                Circle()
                                    .fill(choice.color.gradient)
                                    .frame(width: 34, height: 34)
                                    .padding(4)
                                    .overlay {
                                        if choice == color {
                                            Circle().strokeBorder(choice.color, lineWidth: 2.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(choice.title))
                            .accessibilityAddTraits(choice == color ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ListSymbols.all, id: \.self) { item in
                            Button {
                                withAnimation(.snappy) { symbol = item }
                            } label: {
                                Image(systemName: item)
                                    .font(.system(size: 17, weight: .medium))
                                    .frame(width: 42, height: 42)
                                    .foregroundStyle(item == symbol ? Color.white : Color.primary)
                                    .background(item == symbol ? AnyShapeStyle(color.color.gradient) : AnyShapeStyle(.fill.tertiary),
                                                in: .circle)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(item == symbol ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(request.list == nil ? Text("New List") : Text("Edit List"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        model.saveList(request.list, name: trimmedName, symbol: symbol, color: color)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                    .accessibilityIdentifier("saveListButton")
                }
            }
            .onAppear {
                if request.list == nil {
                    nameFocused = true
                }
            }
        }
    }
}
