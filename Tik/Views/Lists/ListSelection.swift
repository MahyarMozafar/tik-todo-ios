import SwiftUI

/// The built-in lists that collect tasks from every list.
enum SmartList: String, CaseIterable, Identifiable {
    case today
    case scheduled
    case all
    case completed

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .scheduled: "Scheduled"
        case .all: "All"
        case .completed: "Completed"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.max.fill"
        case .scheduled: "calendar"
        case .all: "tray.full.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .today: .orange
        case .scheduled: .red
        case .all: .indigo
        case .completed: .green
        }
    }
}

/// A place in the Lists tab that shows tasks.
enum ListSelection: Hashable {
    case smart(SmartList)
    case inbox
    case list(TaskList)
}

/// SF Symbols to pick from for a list.
enum ListSymbols {
    static let all = [
        "list.bullet", "house.fill", "briefcase.fill", "cart.fill", "heart.fill", "star.fill",
        "book.fill", "graduationcap.fill", "dumbbell.fill", "figure.run", "fork.knife", "cup.and.saucer.fill",
        "airplane", "car.fill", "gift.fill", "flag.fill", "bolt.fill", "leaf.fill",
        "pawprint.fill", "gamecontroller.fill", "music.note", "paintbrush.fill", "laptopcomputer",
        "chevron.left.forwardslash.chevron.right", "person.2.fill", "banknote.fill", "pills.fill",
        "sparkles", "moon.fill", "sun.max.fill",
    ]
}
