import SwiftUI

/// Applies the settings that affect every screen: language, calendar,
/// colors and theme.
struct AppRoot: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(PrefKey.language, store: .tik) private var language: AppLanguage = .english
    @AppStorage(PrefKey.calendar, store: .tik) private var calendarKind: CalendarKind = .persian
    @AppStorage(PrefKey.use24Hour, store: .tik) private var use24Hour = true
    @AppStorage(PrefKey.theme, store: .tik) private var theme: AppTheme = .system
    @AppStorage(PrefKey.accent, store: .tik) private var accent: AccentChoice = .blue

    var body: some View {
        let formatting = DateFormatting(language: language, calendarKind: calendarKind, use24Hour: use24Hour)

        RootView()
            .id(model.contextID)
            .environment(\.modelContext, model.context)
            .environment(\.appLanguage, language)
            .environment(\.dateFormatting, formatting)
            .environment(\.accent, accent)
            .environment(\.locale, formatting.locale)
            .environment(\.calendar, formatting.calendar)
            .environment(\.layoutDirection, language.layoutDirection)
            .tint(accent.color)
            .preferredColorScheme(theme.colorScheme)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.reloadIfChangedElsewhere()
                }
            }
            .onChange(of: language) { _, newLanguage in
                // Reminder buttons and texts follow the app's language.
                Reminders.registerActions(language: newLanguage)
                model.refreshReminders()
                // The few words iOS draws itself (like "Cancel" in search)
                // follow this after the next launch.
                UserDefaults.standard.set([newLanguage.rawValue], forKey: "AppleLanguages")
            }
            .onChange(of: use24Hour) {
                model.refreshReminders()
            }
    }
}
