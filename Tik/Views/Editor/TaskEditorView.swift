import PhotosUI
import SwiftData
import SwiftUI

/// Adds a new task or edits one. Sections that are turned off in Settings
/// (notes, subtasks, dates, priority, photos) are left out.
struct TaskEditorView: View {
    let request: EditorRequest

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.dateFormatting) private var formatting

    @Query(sort: \TaskList.sortIndex) private var lists: [TaskList]

    @AppStorage(PrefKey.fieldNotes, store: .tik) private var notesEnabled = true
    @AppStorage(PrefKey.fieldSubtasks, store: .tik) private var subtasksEnabled = true
    @AppStorage(PrefKey.fieldDates, store: .tik) private var datesEnabled = true
    @AppStorage(PrefKey.fieldRepeat, store: .tik) private var repeatEnabled = true
    @AppStorage(PrefKey.fieldPriority, store: .tik) private var priorityEnabled = true
    @AppStorage(PrefKey.fieldPhotos, store: .tik) private var photosEnabled = true

    @State private var draft: TaskDraft
    @State private var original: TaskDraft
    @State private var photo: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhoto = false
    @State private var confirmDiscard = false
    @State private var confirmDelete = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case title
        case note
        case subtask(UUID)
    }

    init(request: EditorRequest) {
        self.request = request
        let draft = TaskDraft(request: request)
        _draft = State(initialValue: draft)
        _original = State(initialValue: draft)
        _photo = State(initialValue: draft.photoData.flatMap(UIImage.init(data:)))
    }

    private var isNew: Bool { request.task == nil }
    private var hasChanges: Bool { draft != original }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                if datesEnabled {
                    whenSection
                }
                organizeSection
                if subtasksEnabled {
                    subtasksSection
                }
                if photosEnabled {
                    photoSection
                }
                if !isNew {
                    deleteSection
                }
            }
            .navigationTitle(isNew ? Text("New Task") : Text("Edit Task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel, action: cancel)
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .disabled(!draft.canSave)
                        .accessibilityIdentifier("saveButton")
                }
            }
            .interactiveDismissDisabled(hasChanges)
            .confirmationDialog("Discard your changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .confirmationDialog("Delete this task?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete Task", role: .destructive, action: delete)
            }
            .fullScreenCover(isPresented: $showPhoto) {
                if let photo {
                    PhotoViewer(image: photo)
                }
            }
            .onChange(of: photoItem) { _, item in
                loadPhoto(item)
            }
            .onAppear {
                if isNew && draft.title.isEmpty {
                    focus = .title
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("What do you want to do?", text: $draft.title)
                .tikFont(.title3, weight: .semibold)
                .focused($focus, equals: .title)
                .submitLabel(.done)
                .accessibilityIdentifier("titleField")

            if notesEnabled {
                TextField("Notes", text: $draft.note, axis: .vertical)
                    .lineLimit(2...8)
                    .focused($focus, equals: .note)
            }
        }
    }

    private var whenSection: some View {
        Section {
            Toggle(isOn: $draft.hasDate.animation(.snappy)) {
                Label("Date", systemImage: "calendar")
            }

            if draft.hasDate {
                DatePicker("Day", selection: $draft.day, displayedComponents: .date)

                HStack(spacing: 8) {
                    dayShortcut("Today", daysFromNow: 0)
                    dayShortcut("Tomorrow", daysFromNow: 1)
                    dayShortcut("Next Week", daysFromNow: 7)
                }

                Toggle(isOn: $draft.hasTime.animation(.snappy)) {
                    Label("Time", systemImage: "clock")
                }

                if draft.hasTime {
                    DatePicker("Time", selection: $draft.time, displayedComponents: .hourAndMinute)
                }

                if repeatEnabled {
                    NavigationLink {
                        RepeatPickerView(rule: $draft.repeatRule, day: draft.day)
                    } label: {
                        LabeledContent {
                            Text(draft.repeatRule?.summary(formatting: formatting) ?? L10n.string("Never", formatting.language))
                        } label: {
                            Label("Repeat", systemImage: "repeat")
                        }
                    }
                }
            }
        }
    }

    private var organizeSection: some View {
        Section {
            Picker(selection: $draft.list) {
                Label("Inbox", systemImage: "tray").tag(TaskList?.none)
                ForEach(lists) { list in
                    Label(list.name, systemImage: list.symbol).tag(TaskList?.some(list))
                }
            } label: {
                Label("List", systemImage: "list.bullet")
            }

            if priorityEnabled {
                Picker(selection: $draft.priority) {
                    ForEach(Priority.allCases) { priority in
                        Text(priority.title).tag(priority)
                    }
                } label: {
                    Label("Priority", systemImage: "exclamationmark.circle")
                }
            }
        }
    }

    private var subtasksSection: some View {
        Section("Subtasks") {
            ForEach($draft.subtasks) { $subtask in
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.snappy) { subtask.isDone.toggle() }
                    } label: {
                        CheckCircle(isDone: subtask.isDone, size: 20)
                    }
                    .buttonStyle(.plain)

                    TextField("Subtask", text: $subtask.title)
                        .focused($focus, equals: .subtask(subtask.id))
                        .submitLabel(.next)
                        .onSubmit { addSubtask(after: subtask.id) }
                        .foregroundStyle(subtask.isDone ? .secondary : .primary)
                }
            }
            .onDelete { draft.subtasks.remove(atOffsets: $0) }
            .onMove { draft.subtasks.move(fromOffsets: $0, toOffset: $1) }

            Button {
                addSubtask(after: nil)
            } label: {
                Label("Add Subtask", systemImage: "plus.circle.fill")
            }
        }
    }

    private var photoSection: some View {
        Section {
            if let photo {
                Button {
                    showPhoto = true
                } label: {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .clipShape(.rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .accessibilityLabel(Text("Photo"))
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(photo == nil ? LocalizedStringKey("Add Photo") : "Change Photo",
                      systemImage: "photo.on.rectangle")
            }

            if photo != nil {
                Button(role: .destructive) {
                    withAnimation {
                        draft.photoData = nil
                        photo = nil
                        photoItem = nil
                    }
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    // MARK: - Pieces

    private func dayShortcut(_ title: LocalizedStringKey, daysFromNow: Int) -> some View {
        let day = calendar.date(byAdding: .day, value: daysFromNow, to: calendar.startOfDay(for: .now))!
        let isSelected = calendar.isDate(draft.day, inSameDayAs: day)

        return Button {
            withAnimation(.snappy) { draft.day = day }
        } label: {
            Text(title)
                .tikFont(.subheadline, weight: .medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func addSubtask(after id: UUID?) {
        let new = SubtaskDraft(title: "")
        if let id, let index = draft.subtasks.firstIndex(where: { $0.id == id }) {
            // Return on an empty subtask just closes the keyboard.
            guard !draft.subtasks[index].title.trimmingCharacters(in: .whitespaces).isEmpty else {
                focus = nil
                return
            }
            draft.subtasks.insert(new, at: index + 1)
        } else {
            draft.subtasks.append(new)
        }
        Task { @MainActor in
            focus = .subtask(new.id)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task { @MainActor in
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let resized = ImageResizer.jpegData(from: data) else { return }
            withAnimation {
                draft.photoData = resized
                photo = UIImage(data: resized)
            }
        }
    }

    private func cancel() {
        if hasChanges {
            confirmDiscard = true
        } else {
            dismiss()
        }
    }

    private func save() {
        model.save(draft, to: request.task)
        dismiss()
    }

    private func delete() {
        if let task = request.task {
            model.delete(task)
        }
        dismiss()
    }
}
