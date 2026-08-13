import Foundation

enum HabitLogSource: String, Codable, Sendable {
    case manual
    case timer
    case importSource
}

struct HabitLog: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var habitID: UUID
    var date: Date
    var value: Double
    var completed: Bool
    var source: HabitLogSource
    var createdAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        date: Date,
        value: Double,
        completed: Bool,
        source: HabitLogSource = .manual,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.value = max(0, value)
        self.completed = completed
        self.source = source
        self.createdAt = createdAt
    }
}
