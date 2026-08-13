import Foundation

enum CYRDestination: String, CaseIterable, Identifiable, Codable, CustomStringConvertible {
    case create
    case discover
    case journal
    case library
    case me

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .create: return "Create"
        case .discover: return "Discover"
        case .journal: return "Journal"
        case .library: return "Library"
        case .me: return "Me"
        }
    }

    var symbolName: String {
        switch self {
        case .create: return "sparkles"
        case .discover: return "globe"
        case .journal: return "book.pages"
        case .library: return "books.vertical"
        case .me: return "person.crop.circle"
        }
    }

    var description: String { displayTitle }
}
