import Foundation

enum FocusSessionStatus: String, Codable, Sendable {
    case active
    case completed
    case cancelled
}

struct FocusSession: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var scheduledBlockID: UUID?
    var actionID: UUID?
    var startDate: Date
    var endDate: Date?
    var actualDuration: TimeInterval
    var status: FocusSessionStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        scheduledBlockID: UUID? = nil,
        actionID: UUID? = nil,
        startDate: Date,
        endDate: Date? = nil,
        actualDuration: TimeInterval = 0,
        status: FocusSessionStatus = .active,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scheduledBlockID = scheduledBlockID
        self.actionID = actionID
        self.startDate = startDate
        self.endDate = endDate
        self.actualDuration = max(0, actualDuration)
        self.status = status
        self.createdAt = createdAt
    }
}
