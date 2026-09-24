import SwiftUI

/// How important a task is. Saved as an Int so tasks can be sorted by it.
enum Priority: Int, CaseIterable, Identifiable, Codable, Sendable {
    case none = 0
    case low
    case medium
    case high

    var id: Int { rawValue }

    /// "!", "!!" or "!!!", the way the priority shows next to a task.
    var marks: String {
        String(repeating: "!", count: rawValue)
    }

    var title: LocalizedStringKey {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var color: Color {
        switch self {
        case .none: .secondary
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }
}
