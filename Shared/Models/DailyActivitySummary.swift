import Foundation

struct DailyActivitySummary: Codable, Hashable, Sendable {
    var date: Date
    var plannedWork: Int
    var completedWork: Int
    var completedActions: Int
    var focusTime: TimeInterval
    var goalLinkedProgress: Double
    var dailyProgressPercentage: Double
    var reflectionSummary: DailyReflectionSummary
    var activeFocusSession: ActiveFocusSession?

    init(
        date: Date,
        plannedWork: Int,
        completedWork: Int,
        completedActions: Int,
        focusTime: TimeInterval,
        goalLinkedProgress: Double,
        dailyProgressPercentage: Double,
        reflectionSummary: DailyReflectionSummary = .init(),
        activeFocusSession: ActiveFocusSession? = nil
    ) {
        self.date = date
        self.plannedWork = plannedWork
        self.completedWork = completedWork
        self.completedActions = completedActions
        self.focusTime = focusTime
        self.goalLinkedProgress = goalLinkedProgress
        self.dailyProgressPercentage = dailyProgressPercentage
        self.reflectionSummary = reflectionSummary
        self.activeFocusSession = activeFocusSession
    }
}
