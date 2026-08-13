import Foundation

enum TimelineScale: String, CaseIterable, Identifiable, Sendable {
    case month
    case quarter

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum TimelineItemKind: String, Codable, Sendable {
    case goal
    case milestone
    case project
    case action
}

enum TimelineEntityID: Hashable, Sendable {
    case goal(UUID)
    case milestone(UUID)
    case project(UUID)
    case action(UUID)

    var rawID: UUID {
        switch self {
        case .goal(let id), .milestone(let id), .project(let id), .action(let id): id
        }
    }

    var kind: TimelineItemKind {
        switch self {
        case .goal: .goal
        case .milestone: .milestone
        case .project: .project
        case .action: .action
        }
    }
}

struct TimelineNode: Identifiable, Hashable, Sendable {
    var id: TimelineEntityID
    var title: String
    var startDate: Date?
    var targetDate: Date?
    var children: [TimelineNode]

    var kind: TimelineItemKind { id.kind }
    var hasTimeline: Bool { startDate != nil && targetDate != nil }
}

struct TimelineRow: Identifiable, Hashable, Sendable {
    var id: TimelineEntityID { node.id }
    var node: TimelineNode
    var depth: Int
}
