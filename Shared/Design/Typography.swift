import SwiftUI

/// Sets a font that fits the language picked in the app.
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
