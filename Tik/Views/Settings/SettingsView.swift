import SwiftUI
import WidgetKit

/// Everything that can be changed: language and calendar, the look, the
/// feel, which task details to use, and reminders.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(PrefKey.language, store: .tik) private var language: AppLanguage = .english
    @AppStorage(PrefKey.calendar, store: .tik) private var calendarKind: CalendarKind = .persian
    @AppStorage(PrefKey.use24Hour, store: .tik) private var use24Hour = true

    @AppStorage(PrefKey.theme, store: .tik) private var theme: AppTheme = .system
    @AppStorage(PrefKey.accent, store: .tik) private var accent: AccentChoice = .blue
    @AppStorage(PrefKey.colorfulBackground, store: .tik) private var colorfulBackground = true

    @AppStorage(PrefKey.sortOrder, store: .tik) private var sortOrder: TaskSortOrder = .time
    @AppStorage(PrefKey.showProgress, store: .tik) private var showProgress = true
    @AppStorage(PrefKey.showCompletedInToday, store: .tik) private var showCompletedInToday = true

    @AppStorage(PrefKey.haptics, store: .tik) private var haptics = true
    @AppStorage(PrefKey.sounds, store: .tik) private var sounds = true
    @AppStorage(PrefKey.celebration, store: .tik) private var celebration = true

    @AppStorage(PrefKey.fieldNotes, store: .tik) private var fieldNotes = true
    @AppStorage(PrefKey.fieldSubtasks, store: .tik) private var fieldSubtasks = true
    @AppStorage(PrefKey.fieldDates, store: .tik) private var fieldDates = true
    @AppStorage(PrefKey.fieldRepeat, store: .tik) private var fieldRepeat = true
    @AppStorage(PrefKey.fieldPriority, store: .tik) private var fieldPriority = true
    @AppStorage(PrefKey.fieldPhotos, store: .tik) private var fieldPhotos = true

    @AppStorage(PrefKey.reminderOffset, store: .tik) private var reminderOffset = 0
    @AppStorage(PrefKey.badge, store: .tik) private var badge = false

    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                appearanceSection
                todaySection
                feelSection
                detailsSection
                remindersSection
                aboutSection
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                        .accessibilityIdentifier("closeSettings")
                }
            }
            .task {
                notificationsDenied = await Reminders.isDenied()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { notificationsDenied = await Reminders.isDenied() }
            }
            .onChange(of: reminderOffset) {
                model.refreshReminders()
            }
            .onChange(of: badge) { _, isOn in
                Task {
                    if isOn {
                        await Reminders.requestPermission()
                    }
                    model.updateBadge()
                }
            }
            .onChange(of: language) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: calendarKind) { WidgetCenter.shared.reloadAllTimelines() }
            .onChange(of: accent) { WidgetCenter.shared.reloadAllTimelines() }
        }
    }

    // MARK: - Sections

    private var languageSection: some View {
        Section("Language & Calendar") {
            Picker(selection: $language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(verbatim: language.nativeName).tag(language)
                }
            } label: {
                SettingsLabel("Language", symbol: "globe", color: .blue)
            }
            .accessibilityIdentifier("languagePicker")

            Picker(selection: $calendarKind) {
                ForEach(CalendarKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            } label: {
                SettingsLabel("Calendar", symbol: "calendar", color: .red)
            }

            Toggle(isOn: $use24Hour) {
                SettingsLabel("24-Hour Time", symbol: "clock.fill", color: .orange)
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: $theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            } label: {
                SettingsLabel("Theme", symbol: "circle.lefthalf.filled", color: .indigo)
            }

            AccentColorPicker(selection: $accent)

            Toggle(isOn: $colorfulBackground) {
                SettingsLabel("Colorful Background", symbol: "paintpalette.fill", color: .pink)
            }
        }
    }

    private var todaySection: some View {
        Section("Today") {
            Picker(selection: $sortOrder) {
                ForEach(TaskSortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            } label: {
                SettingsLabel("Sort Tasks By", symbol: "arrow.up.arrow.down", color: .teal)
            }

            Toggle(isOn: $showProgress) {
                SettingsLabel("Show Progress", symbol: "chart.bar.fill", color: .green)
            }

            Toggle(isOn: $showCompletedInToday) {
                SettingsLabel("Keep Done Tasks Until Tomorrow", symbol: "checkmark.circle.fill", color: .mint)
            }
        }
    }

    private var feelSection: some View {
        Section("Feel") {
            Toggle(isOn: $haptics) {
                SettingsLabel("Haptics", symbol: "hand.tap.fill", color: .purple)
            }
            Toggle(isOn: $sounds) {
                SettingsLabel("Sounds", symbol: "speaker.wave.2.fill", color: .pink)
            }
            Toggle(isOn: $celebration) {
                SettingsLabel("Confetti When All Done", symbol: "party.popper.fill", color: .orange)
            }
        }
    }

    private var detailsSection: some View {
        Section {
            Toggle(isOn: $fieldNotes) {
                SettingsLabel("Notes", symbol: "text.alignleft", color: .gray)
            }
            Toggle(isOn: $fieldSubtasks) {
                SettingsLabel("Subtasks", symbol: "checklist", color: .blue)
            }
            Toggle(isOn: $fieldDates) {
                SettingsLabel("Date & Time", symbol: "calendar.badge.clock", color: .red)
            }
            Toggle(isOn: $fieldRepeat) {
                SettingsLabel("Repeat", symbol: "repeat", color: .green)
            }
            .disabled(!fieldDates)
            Toggle(isOn: $fieldPriority) {
                SettingsLabel("Priority", symbol: "exclamationmark", color: .orange)
            }
            Toggle(isOn: $fieldPhotos) {
                SettingsLabel("Photos", symbol: "photo.fill", color: .cyan)
            }
        } header: {
            Text("Task Details")
        } footer: {
            Text("Turn off what you don't use. It is hidden when you add or edit a task.")
        }
    }

    private var remindersSection: some View {
        Section {
            Picker(selection: $reminderOffset) {
                Text("At the Time of the Task").tag(0)
                Text("5 Minutes Before").tag(5)
                Text("15 Minutes Before").tag(15)
                Text("30 Minutes Before").tag(30)
                Text("1 Hour Before").tag(60)
            } label: {
                SettingsLabel("Remind Me", symbol: "bell.fill", color: .red)
            }

            Toggle(isOn: $badge) {
                SettingsLabel("Count on App Icon", symbol: "app.badge.fill", color: .red)
            }

            if notificationsDenied {
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Turn On Notifications in Settings", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Reminders are sent for tasks that have a time.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent {
                Text(verbatim: appVersion)
            } label: {
                SettingsLabel("Version", symbol: "info", color: .gray)
            }
            Link(destination: URL(string: "https://github.com/MahyarMozafar/tik-todo-ios")!) {
                SettingsLabel("Source Code", symbol: "chevron.left.forwardslash.chevron.right", color: .black)
            }
        } footer: {
            Text("Made by Mahyar Mozafar.")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

/// A settings row title with a small colored icon, like the iOS Settings app.
struct SettingsLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color

    init(_ title: LocalizedStringKey, symbol: String, color: Color) {
        self.title = title
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color.gradient, in: .rect(cornerRadius: 7))
        }
    }
}

/// A row of color dots for the accent color.
struct AccentColorPicker: View {
    @Binding var selection: AccentChoice

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsLabel("Accent Color", symbol: "paintbrush.pointed.fill", color: selection.color)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AccentChoice.allCases) { choice in
                    Button {
                        withAnimation(.snappy) { selection = choice }
                    } label: {
                        Circle()
                            .fill(choice.color.gradient)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if choice == selection {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(3)
                            .overlay {
                                if choice == selection {
                                    Circle().strokeBorder(choice.color.opacity(0.5), lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(choice.title))
                    .accessibilityAddTraits(choice == selection ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 6)
    }
}
