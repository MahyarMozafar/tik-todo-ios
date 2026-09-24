import SwiftUI

/// Keys for everything that can be changed in Settings.
///
/// The values live in the App Group's `UserDefaults`, so the widget sees the
/// same language, calendar and colors as the app.
enum PrefKey {
    static let language = "language"
    static let calendar = "calendar"
    static let use24Hour = "use24Hour"

    static let theme = "theme"
    static let accent = "accent"
    static let colorfulBackground = "colorfulBackground"

    static let sortOrder = "sortOrder"
    static let showProgress = "showProgress"
    static let showCompletedInToday = "showCompletedInToday"

    static let haptics = "haptics"
    static let sounds = "sounds"
    static let celebration = "celebration"

    static let fieldNotes = "field.notes"
    static let fieldSubtasks = "field.subtasks"
    static let fieldDates = "field.dates"
    static let fieldRepeat = "field.repeat"
    static let fieldPriority = "field.priority"
    static let fieldPhotos = "field.photos"

    static let reminderOffset = "reminderOffset"
    static let badge = "badge"

    /// Changed by the widget after it edits a task, so the app knows to reload.
    static let externalChange = "externalChange"
    static let didCreateStarterLists = "didCreateStarterLists"
}

extension UserDefaults {
    /// Shared by the app and the widget.
    static let tik = UserDefaults(suiteName: SharedStore.appGroupID) ?? .standard

    /// Default values, so a setting that was never touched still reads right.
    static func registerTikDefaults() {
        tik.register(defaults: [
            PrefKey.language: AppLanguage.english.rawValue,
            PrefKey.calendar: CalendarKind.persian.rawValue,
            PrefKey.use24Hour: true,
            PrefKey.theme: AppTheme.system.rawValue,
            PrefKey.accent: AccentChoice.blue.rawValue,
            PrefKey.colorfulBackground: true,
            PrefKey.sortOrder: TaskSortOrder.time.rawValue,
            PrefKey.showProgress: true,
            PrefKey.showCompletedInToday: true,
            PrefKey.haptics: true,
            PrefKey.sounds: true,
            PrefKey.celebration: true,
            PrefKey.fieldNotes: true,
            PrefKey.fieldSubtasks: true,
            PrefKey.fieldDates: true,
            PrefKey.fieldRepeat: true,
            PrefKey.fieldPriority: true,
            PrefKey.fieldPhotos: true,
            PrefKey.reminderOffset: 0,
            PrefKey.badge: false,
        ])
    }
}

/// A snapshot of the settings, for code that is not a view
/// (notifications, the widget, App Intents).
struct Preferences {
    var language: AppLanguage
    var calendarKind: CalendarKind
    var use24Hour: Bool
    var accent: AccentChoice
    var sortOrder: TaskSortOrder
    var showCompletedInToday: Bool
    var reminderOffset: Int
    var showsBadge: Bool

    static func current(_ defaults: UserDefaults = .tik) -> Preferences {
        Preferences(
            language: AppLanguage(rawValue: defaults.string(forKey: PrefKey.language) ?? "") ?? .english,
            calendarKind: CalendarKind(rawValue: defaults.string(forKey: PrefKey.calendar) ?? "") ?? .persian,
            use24Hour: defaults.object(forKey: PrefKey.use24Hour) as? Bool ?? true,
            accent: AccentChoice(rawValue: defaults.string(forKey: PrefKey.accent) ?? "") ?? .blue,
            sortOrder: TaskSortOrder(rawValue: defaults.string(forKey: PrefKey.sortOrder) ?? "") ?? .time,
            showCompletedInToday: defaults.object(forKey: PrefKey.showCompletedInToday) as? Bool ?? true,
            reminderOffset: defaults.integer(forKey: PrefKey.reminderOffset),
            showsBadge: defaults.bool(forKey: PrefKey.badge)
        )
    }

    var formatting: DateFormatting {
        DateFormatting(language: language, calendarKind: calendarKind, use24Hour: use24Hour)
    }
}

// MARK: - Choices

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case farsi = "fa"

    var id: String { rawValue }

    /// Each language is written in itself, so it is easy to find.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .farsi: "\u{0641}\u{0627}\u{0631}\u{0633}\u{06CC}"
        }
    }

    var layoutDirection: LayoutDirection {
        self == .farsi ? .rightToLeft : .leftToRight
    }

    /// A locale for this language that always writes English digits.
    var numberLocale: Locale {
        var components = Locale.Components(identifier: self == .farsi ? "fa_IR" : "en_US")
        components.numberingSystem = Locale.NumberingSystem("latn")
        return Locale(components: components)
    }
}

enum CalendarKind: String, CaseIterable, Identifiable {
    case persian
    case gregorian

    var id: String { rawValue }

    var identifier: Calendar.Identifier {
        self == .persian ? .persian : .gregorian
    }

    var title: LocalizedStringKey {
        self == .persian ? "Shamsi" : "Gregorian"
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case blue
    case indigo
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case mint
    case teal
    case graphite

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .graphite: .gray
        }
    }

    /// A second color that goes well with this one, for soft backgrounds.
    var partner: Color {
        switch self {
        case .blue: .purple
        case .indigo: .cyan
        case .purple: .pink
        case .pink: .orange
        case .red: .orange
        case .orange: .pink
        case .yellow: .orange
        case .green: .teal
        case .mint: .blue
        case .teal: .indigo
        case .graphite: .blue
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .mint: "Mint"
        case .teal: "Teal"
        case .graphite: "Graphite"
        }
    }
}

enum TaskSortOrder: String, CaseIterable, Identifiable {
    case time
    case priority
    case newest

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .time: "Time"
        case .priority: "Priority"
        case .newest: "Newest"
        }
    }
}
