import Foundation

struct ActivityCategory: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var title: String
}

struct TrackedActivity: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var title: String
    var category: ActivityCategory
    var duration: TimeInterval
    var plannedDuration: TimeInterval?
    var goalID: UUID?

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        category: ActivityCategory,
        duration: TimeInterval,
        plannedDuration: TimeInterval? = nil,
        goalID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.category = category
        self.duration = max(0, duration)
        self.plannedDuration = plannedDuration.map { max(0, $0) }
        self.goalID = goalID
    }
}

struct DailyTrackingRecord: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var plannedActions: Int
    var completedActions: Int
    var goalLinkedActions: Int
    var completedGoalLinkedActions: Int
    var plannedFocusTime: TimeInterval
    var activities: [TrackedActivity]
    var reflection: DailyReflectionSummary
    var reflectionCompleted: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        plannedActions: Int = 0,
        completedActions: Int = 0,
        goalLinkedActions: Int = 0,
        completedGoalLinkedActions: Int = 0,
        plannedFocusTime: TimeInterval = 0,
        activities: [TrackedActivity] = [],
        reflection: DailyReflectionSummary = .init(),
        reflectionCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.plannedActions = max(0, plannedActions)
        self.completedActions = max(0, completedActions)
        self.goalLinkedActions = max(0, goalLinkedActions)
        self.completedGoalLinkedActions = max(0, completedGoalLinkedActions)
        self.plannedFocusTime = max(0, plannedFocusTime)
        self.activities = activities
        self.reflection = reflection
        self.reflectionCompleted = reflectionCompleted
    }

    var actualFocusTime: TimeInterval {
        activities.reduce(0) { $0 + $1.duration }
    }
}
