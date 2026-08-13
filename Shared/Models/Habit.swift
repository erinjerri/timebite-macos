import Foundation

enum HabitTrackingType: String, CaseIterable, Codable, Sendable {
    case boolean
    case count
    case duration
    case quantity
}

enum HabitRecurrence: String, CaseIterable, Codable, Sendable {
    case daily
    case weekdays
    case weekly
}

struct Habit: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var lifeAreaID: UUID?
    var goalID: UUID?
    var trackingType: HabitTrackingType
    var targetValue: Double?
    var unit: String?
    var recurrence: HabitRecurrence
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        lifeAreaID: UUID? = nil,
        goalID: UUID? = nil,
        trackingType: HabitTrackingType,
        targetValue: Double? = nil,
        unit: String? = nil,
        recurrence: HabitRecurrence = .daily,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.lifeAreaID = lifeAreaID
        self.goalID = goalID
        self.trackingType = trackingType
        self.targetValue = targetValue
        self.unit = unit
        self.recurrence = recurrence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
