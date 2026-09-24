import SwiftUI
import UIKit

/// Sets a font that fits the language picked in the app: the system font
/// for English, and Vazirmatn for Farsi.
struct TikFont: ViewModifier {
    @Environment(\.appLanguage) private var language

    var style: Font.TextStyle
    var size: CGFloat?
    var weight: Font.Weight
    var design: Font.Design

    func body(content: Content) -> some View {
        content.font(font)
    }

    private var font: Font {
        if language == .farsi {
            let name = Vazirmatn.name(for: weight)
            if let size {
                return .custom(name, fixedSize: size)
            }
            return .custom(name, size: style.defaultSize, relativeTo: style)
        }
        if let size {
            return .system(size: size, weight: weight, design: design)
        }
        return .system(style, design: design, weight: weight)
    }
}

extension View {
    /// A text style (like `.body`) that grows with the user's text size.
    func tikFont(_ style: Font.TextStyle, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(TikFont(style: style, size: nil, weight: weight, design: design))
    }

    /// A fixed point size, for big numbers and widgets.
    func tikFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(TikFont(style: .body, size: size, weight: weight, design: design))
    }
}

/// The Farsi font, bundled in four weights.
enum Vazirmatn {
    static func name(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: "Vazirmatn-Bold"
        case .semibold: "Vazirmatn-SemiBold"
        case .medium: "Vazirmatn-Medium"
        default: "Vazirmatn-Regular"
        }
    }

    /// The default font for a whole screen in the given language, or nil
    /// to keep the system font.
    static func body(for language: AppLanguage) -> Font? {
        language == .farsi ? .custom("Vazirmatn-Regular", size: 17, relativeTo: .body) : nil
    }

    /// Navigation bar titles are drawn by UIKit, so their font is set here.
    @MainActor
    static func applyToNavigationBars(for language: AppLanguage) {
        let appearance = UINavigationBar.appearance()
        guard language == .farsi,
              let large = UIFont(name: "Vazirmatn-Bold", size: 34),
              let inline = UIFont(name: "Vazirmatn-SemiBold", size: 17) else {
            appearance.largeTitleTextAttributes = nil
            appearance.titleTextAttributes = nil
            return
        }
        appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
    }
}

extension Font.TextStyle {
    /// Point sizes at the default text size, used to scale custom fonts.
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}
