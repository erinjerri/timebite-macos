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

enum LifeArea: String, CaseIterable, Codable, Identifiable, Sendable {
    case health
    case work
    case home
    case relationships
    case finance
    case learning
    case play
    case errands
    case other

    var id: UUID {
        switch self {
        case .health: return UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        case .work: return UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
        case .home: return UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
        case .relationships: return UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
        case .finance: return UUID(uuidString: "55555555-5555-4555-8555-555555555555")!
        case .learning: return UUID(uuidString: "66666666-6666-4666-8666-666666666666")!
        case .play: return UUID(uuidString: "77777777-7777-4777-8777-777777777777")!
        case .errands: return UUID(uuidString: "88888888-8888-4888-8888-888888888888")!
        case .other: return UUID(uuidString: "99999999-9999-4999-8999-999999999999")!
        }
    }

    var title: String {
        switch self {
        case .health: return "Health"
        case .work: return "Work"
        case .home: return "Home"
        case .relationships: return "Relationships"
        case .finance: return "Finance"
        case .learning: return "Learning"
        case .play: return "Play"
        case .errands: return "Errands"
        case .other: return "Other"
        }
    }
}

struct Goal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var categoryID: UUID?
    var notes: String
    var startDate: Date?
    var targetDate: Date?
    var status: PlanningEntityStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        categoryID: UUID? = nil,
        notes: String = "",
        startDate: Date? = nil,
        targetDate: Date? = nil,
        status: PlanningEntityStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.notes = notes
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, categoryID, notes, startDate, targetDate, status, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate)
        status = try container.decodeIfPresent(PlanningEntityStatus.self, forKey: .status) ?? .active
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
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
    var workLabel: String?
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
        workLabel: String? = nil,
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
        self.workLabel = workLabel
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
