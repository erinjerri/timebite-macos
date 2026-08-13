import Foundation

struct DailyAlignment: Hashable, Sendable {
    var overall: Double
    var focus: Double
    var actions: Double
    var goals: Double
    var reflection: Double
}

struct DailyTrackingSummary: Identifiable, Hashable, Sendable {
    var id: Date { date }
    var date: Date
    var alignment: DailyAlignment
    var focusTime: TimeInterval
    var plannedFocusTime: TimeInterval
    var completedActions: Int
    var goalLinkedActions: Int
    var habitCompletion: Double?
    var activities: [TrackedActivity]
    var reflection: DailyReflectionSummary
    var hasData: Bool
}

struct WeeklyTrackingSummary: Hashable, Sendable {
    var days: [DailyTrackingSummary]
    var totalFocusTime: TimeInterval
    var completedActions: Int
    var goalLinkedActions: Int
    var habitCompletion: Double?
    var plannedFocusTime: TimeInterval
    var hasData: Bool
}

struct MonthlyTrackingSummary: Identifiable, Hashable, Sendable {
    var id: Date { month }
    var month: Date
    var alignment: Double?
    var focusedTime: TimeInterval
    var completedGoals: Int?
    var completedMilestones: Int?
    var habitConsistency: Double?
    var plannedFocusTime: TimeInterval?
    var mostInvestedAreas: [String]
}

enum TrackingMetric: String, CaseIterable, Identifiable, Sendable {
    case overall
    case goal
    case habit
    case focus
    case actions

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CalendarProgressState: Hashable, Sendable {
    case achieved
    case partial
    case noData
}
