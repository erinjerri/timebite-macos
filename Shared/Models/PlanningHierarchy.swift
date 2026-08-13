import Foundation

enum PlanningEntityStatus: String, CaseIterable, Codable, Sendable {
    case active
    case completed
    case paused
    case cancelled
}

enum ActionStatus: String, CaseIterable, Codable, Sendable {
    case inbox
    case planned
    case inProgress
    case completed
    case cancelled
}

enum ActionPriority: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high
}

struct Goal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var notes: String
    var startDate: Date?
    var targetDate: Date?
    var status: PlanningEntityStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        startDate: Date? = nil,
        targetDate: Date? = nil,
        status: PlanningEntityStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Milestone: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var goalID: UUID?
    var title: String
    var notes: String
    var startDate: Date?
    var targetDate: Date?
    var status: PlanningEntityStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        goalID: UUID? = nil,
        title: String,
        notes: String = "",
        startDate: Date? = nil,
        targetDate: Date? = nil,
        status: PlanningEntityStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Project: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var goalID: UUID?
    var milestoneID: UUID?
    var title: String
    var notes: String
    var startDate: Date?
    var targetDate: Date?
    var status: PlanningEntityStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        goalID: UUID? = nil,
        milestoneID: UUID? = nil,
        title: String,
        notes: String = "",
        startDate: Date? = nil,
        targetDate: Date? = nil,
        status: PlanningEntityStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.milestoneID = milestoneID
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Action: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var goalID: UUID?
    var milestoneID: UUID?
    var projectID: UUID?
    var lifeAreaID: UUID?
    var title: String
    var notes: String
    var estimatedDuration: TimeInterval?
    var priority: ActionPriority?
    var startDate: Date?
    var targetDate: Date?
    var status: ActionStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        goalID: UUID? = nil,
        milestoneID: UUID? = nil,
        projectID: UUID? = nil,
        lifeAreaID: UUID? = nil,
        title: String,
        notes: String = "",
        estimatedDuration: TimeInterval? = nil,
        priority: ActionPriority? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        status: ActionStatus = .inbox,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.milestoneID = milestoneID
        self.projectID = projectID
        self.lifeAreaID = lifeAreaID
        self.title = title
        self.notes = notes
        self.estimatedDuration = estimatedDuration.map { max(0, $0) }
        self.priority = priority
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isCompleted: Bool { status == .completed }
}
