import Foundation

enum PortfolioZoomScale: String, CaseIterable, Identifiable, Codable, Sendable {
    case month
    case quarter
    case year

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PortfolioItemKind: String, CaseIterable, Codable, Sendable {
    case lifeArea
    case program
    case project
    case phase
    case milestone
    case action
    case personalConstraint
}

enum PortfolioItemStatus: String, CaseIterable, Codable, Sendable {
    case idea
    case planned
    case active
    case blocked
    case atRisk
    case complete
    case paused
}

enum PortfolioPriority: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high
}

enum PortfolioFlexibility: String, CaseIterable, Codable, Sendable {
    case fixed
    case target
    case flexible
}

enum PortfolioProjectType: String, CaseIterable, Codable, Sendable {
    case venture
    case product
    case creativeBusiness
    case nonprofit
    case career
    case intellectualProperty
    case media
    case personal
}

enum PortfolioCapacity: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high
}

struct Portfolio: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var subtitle: String
    var startDate: Date
    var endDate: Date
    var items: [PortfolioItem]
    var dependencies: [PortfolioDependency]
    var recurringBlocks: [RecurringBlock]
    var decisionGates: [DecisionGate]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        startDate: Date,
        endDate: Date,
        items: [PortfolioItem] = [],
        dependencies: [PortfolioDependency] = [],
        recurringBlocks: [RecurringBlock] = [],
        decisionGates: [DecisionGate] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startDate = startDate
        self.endDate = endDate
        self.items = items
        self.dependencies = dependencies
        self.recurringBlocks = recurringBlocks
        self.decisionGates = decisionGates
    }
}

struct PortfolioItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var subtitle: String
    var startDate: Date
    var endDate: Date
    var status: PortfolioItemStatus
    var priority: PortfolioPriority
    var progress: Double
    var parentID: UUID?
    var tags: [String]
    var owner: String?
    var notes: String
    var confidence: Double?
    var flexibility: PortfolioFlexibility
    var projectType: PortfolioProjectType
    var capacity: PortfolioCapacity
    var kind: PortfolioItemKind
    var linkedActionID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        startDate: Date,
        endDate: Date,
        status: PortfolioItemStatus = .planned,
        priority: PortfolioPriority = .medium,
        progress: Double = 0,
        parentID: UUID? = nil,
        tags: [String] = [],
        owner: String? = nil,
        notes: String = "",
        confidence: Double? = nil,
        flexibility: PortfolioFlexibility = .target,
        projectType: PortfolioProjectType,
        capacity: PortfolioCapacity = .medium,
        kind: PortfolioItemKind,
        linkedActionID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startDate = min(startDate, endDate)
        self.endDate = max(startDate, endDate)
        self.status = status
        self.priority = priority
        self.progress = min(max(progress, 0), 1)
        self.parentID = parentID
        self.tags = tags
        self.owner = owner
        self.notes = notes
        self.confidence = confidence.map { min(max($0, 0), 1) }
        self.flexibility = flexibility
        self.projectType = projectType
        self.capacity = capacity
        self.kind = kind
        self.linkedActionID = linkedActionID
    }

    var isMilestone: Bool { kind == .milestone }
    var isPersonalConstraint: Bool { kind == .personalConstraint }
}

enum DependencyRelationship: String, CaseIterable, Codable, Sendable {
    case finishToStart
    case startToStart
    case finishToFinish
}

struct PortfolioDependency: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var predecessorID: UUID
    var successorID: UUID
    var relationship: DependencyRelationship
    var lagDays: Int

    init(
        id: UUID = UUID(),
        predecessorID: UUID,
        successorID: UUID,
        relationship: DependencyRelationship = .finishToStart,
        lagDays: Int = 0
    ) {
        self.id = id
        self.predecessorID = predecessorID
        self.successorID = successorID
        self.relationship = relationship
        self.lagDays = lagDays
    }
}

enum RecurringCadence: String, CaseIterable, Codable, Sendable {
    case weekly
    case alternatingWeekends
    case protectedWeekend
}

struct RecurringBlock: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var subtitle: String
    var startDate: Date
    var endDate: Date
    var parentID: UUID?
    var cadence: RecurringCadence
    var weekday: Int?
    var intervalWeeks: Int
    var flexibility: PortfolioFlexibility
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        startDate: Date,
        endDate: Date,
        parentID: UUID? = nil,
        cadence: RecurringCadence,
        weekday: Int? = nil,
        intervalWeeks: Int = 1,
        flexibility: PortfolioFlexibility = .flexible,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startDate = min(startDate, endDate)
        self.endDate = max(startDate, endDate)
        self.parentID = parentID
        self.cadence = cadence
        self.weekday = weekday
        self.intervalWeeks = max(1, intervalWeeks)
        self.flexibility = flexibility
        self.notes = notes
    }
}

struct DecisionGate: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var date: Date
    var parentID: UUID?
    var conditions: [String]
    var status: PortfolioItemStatus
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        parentID: UUID? = nil,
        conditions: [String] = [],
        status: PortfolioItemStatus = .planned,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.parentID = parentID
        self.conditions = conditions
        self.status = status
        self.notes = notes
    }
}
