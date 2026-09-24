import SwiftUI
import UIKit

enum AppIconChoice: String, CaseIterable, Identifiable {
    case blue = "AppIcon"
    case midnight = "AppIcon-Midnight"
    case light = "AppIcon-Light"
    case mint = "AppIcon-Mint"
    case purple = "AppIcon-Purple"
    case sunset = "AppIcon-Sunset"

    var id: String { rawValue }

    /// The name iOS needs, or nil for the main icon.
    var alternateName: String? {
        self == .blue ? nil : rawValue
    }

    /// A small copy of the icon, kept as a normal image.
    var previewImage: String {
        "IconPreview-\(rawValue)"
    }

    var title: LocalizedStringKey {
        switch self {
        case .blue: "Blue"
        case .midnight: "Midnight"
        case .light: "Light"
        case .mint: "Mint"
        case .purple: "Purple"
        case .sunset: "Sunset"
        }
    }
}

/// A grid of the app icons to choose from.
struct AppIconPicker: View {
    @State private var current = UIApplication.shared.alternateIconName

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 20) {
                ForEach(AppIconChoice.allCases) { icon in
                    let isSelected = icon.alternateName == current
                    Button {
                        select(icon)
                    } label: {
                        VStack(spacing: 10) {
                            Image(icon.previewImage)
                                .resizable()
                                .frame(width: 76, height: 76)
                                .clipShape(.rect(cornerRadius: 17, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                                        .strokeBorder(.primary.opacity(0.08))
                                }
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                            HStack(spacing: 4) {
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                                Text(icon.title)
                                    .tikFont(.subheadline, weight: isSelected ? .semibold : .regular)
                            }
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .glassEffect(isSelected ? .regular.interactive() : .identity, in: .rect(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(20)
        }
        .background { AppBackground() }
        .navigationTitle(Text("App Icon"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func select(_ icon: AppIconChoice) {
        guard UIApplication.shared.supportsAlternateIcons, icon.alternateName != current else { return }
        Task {
            try? await UIApplication.shared.setAlternateIconName(icon.alternateName)
            withAnimation(.snappy) {
                current = UIApplication.shared.alternateIconName
            }
        }
    }
}
