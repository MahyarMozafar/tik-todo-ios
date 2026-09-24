import SwiftUI

extension EnvironmentValues {
    /// The language picked in Settings (it can differ from the phone's language).
    @Entry var appLanguage: AppLanguage = .english

    /// Formats dates with the calendar and language picked in Settings.
    @Entry var dateFormatting = DateFormatting(language: .english, calendarKind: .persian, use24Hour: true)
}
