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
        @Bindable var model = model
        let formatting = DateFormatting(language: language, calendarKind: calendarKind, use24Hour: use24Hour)

        RootView()
            // Build the screens again when the language changes. Lists that
            // only flip their direction in place can end up drawing mirrored
            // text after going from Farsi back to English.
            .id(RootIdentity(language: language, context: model.contextID))
            // Outside the rebuilt part, so Settings stays open meanwhile.
            .sheet(isPresented: $model.showSettings) {
                SettingsView()
            }
            .environment(\.modelContext, model.context)
            .environment(\.appLanguage, language)
            .environment(\.dateFormatting, formatting)
            .environment(\.accent, accent)
            .environment(\.locale, formatting.locale)
            .environment(\.calendar, formatting.calendar)
            .environment(\.layoutDirection, language.layoutDirection)
            .font(Vazirmatn.body(for: language))
            .tint(accent.color)
            .preferredColorScheme(theme.colorScheme)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.reloadIfChangedElsewhere()
                }
            }
            .onOpenURL { url in
                model.handle(url)
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

/// Changes whenever the screens have to be built from scratch.
private struct RootIdentity: Hashable {
    var language: AppLanguage
    var context: UUID
}
