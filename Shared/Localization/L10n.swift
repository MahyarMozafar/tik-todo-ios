import Foundation

/// Looks up text in the language picked inside the app, not the phone's
/// language.
///
/// SwiftUI's `Text` already does this through the `locale` environment
/// value. This helper is for plain strings made outside of views, such as
/// notification text and widget labels.
enum L10n {
    static func string(_ key: String, _ language: AppLanguage) -> String {
        bundle(for: language).localizedString(forKey: key, value: key, table: nil)
    }

    /// For keys with placeholders, like "%lld tasks".
    static func format(_ key: String, _ language: AppLanguage, _ arguments: CVarArg...) -> String {
        String(format: string(key, language), locale: language.numberLocale, arguments: arguments)
    }

    private static func bundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
