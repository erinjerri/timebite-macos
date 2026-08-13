import Foundation

enum TimeBiteDestination: String, CaseIterable, Identifiable, Codable, CustomStringConvertible {
    case now
    case actions
    case goals
    case plan
    case track
    case dashboard

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .now: return "Now"
        case .actions: return "Actions"
        case .goals: return "Goals"
        case .plan: return "Plan"
        case .track: return "Track"
        case .dashboard: return "Dashboard"
        }
    }

    var symbolName: String {
        switch self {
        case .now: return "dot.radiowaves.left.and.right"
        case .actions: return "checklist"
        case .goals: return "target"
        case .plan: return "calendar"
        case .track: return "chart.line.uptrend.xyaxis"
        case .dashboard: return "rectangle.grid.2x2"
        }
    }

    var description: String { displayTitle }
}
