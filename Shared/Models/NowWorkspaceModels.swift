import Foundation

enum NowAllocationMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case percentage
    case hours

    var id: String { rawValue }

    var title: String {
        switch self {
        case .percentage: "Percentage"
        case .hours: "Hours"
        }
    }
}

enum NowAllocationColorToken: String, CaseIterable, Codable, Identifiable, Sendable {
    case blue
    case green
    case gold
    case violet
    case teal
    case sky
    case neutral

    var id: String { rawValue }
}

enum NowEstimateInputMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case duration
    case timeRange

    var id: String { rawValue }

    var title: String {
        switch self {
        case .duration: "Duration"
        case .timeRange: "Start / end"
        }
    }
}

enum NowTimerEvent: String, CaseIterable, Codable, Identifiable, Sendable {
    case running
    case expired
    case stopped
    case cleared
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .running: "Running"
        case .expired: "Expired"
        case .stopped: "Stopped"
        case .cleared: "Cleared"
        case .completed: "Completed"
        }
    }
}

enum NowRoutinePeriod: String, CaseIterable, Codable, Identifiable, Sendable {
    case morning
    case afternoon
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "PM / evening"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: "Start-up, recovery, and setup"
        case .afternoon: "Work, errands, and momentum"
        case .evening: "Wind-down, care, and closeout"
        }
    }
}

enum NowRoutineCategoryKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case rest
    case fitness
    case eating
    case work
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rest: "Rest / sleep"
        case .fitness: "Fitness / workout"
        case .eating: "Eating"
        case .work: "Work / projects"
        case .personal: "Personal / other"
        }
    }

    var tintToken: NowAllocationColorToken {
        switch self {
        case .rest: .blue
        case .fitness: .green
        case .eating: .gold
        case .work: .sky
        case .personal: .violet
        }
    }

    var symbolName: String {
        switch self {
        case .rest: "bed.double.fill"
        case .fitness: "figure.strengthtraining.traditional"
        case .eating: "fork.knife"
        case .work: "briefcase.fill"
        case .personal: "person.fill"
        }
    }
}

struct BaselineNeed: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var estimateMinutes: Int
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        estimateMinutes: Int,
        notes: String
    ) {
        self.id = id
        self.title = title
        self.estimateMinutes = max(0, estimateMinutes)
        self.notes = notes
    }
}

struct WeeklyAllocationPreset: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var colorToken: NowAllocationColorToken
    var percentage: Double
    var weeklyHours: Double
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        colorToken: NowAllocationColorToken,
        percentage: Double,
        weeklyHours: Double,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.colorToken = colorToken
        self.percentage = max(0, percentage)
        self.weeklyHours = max(0, weeklyHours)
        self.notes = notes
    }
}

struct NowRoutineBlock: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var category: NowRoutineCategoryKind
    var durationMinutes: Int
    var linkedActionID: UUID?
    var linkedProjectID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        category: NowRoutineCategoryKind,
        durationMinutes: Int,
        linkedActionID: UUID? = nil,
        linkedProjectID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.durationMinutes = max(0, durationMinutes)
        self.linkedActionID = linkedActionID
        self.linkedProjectID = linkedProjectID
    }

    var committedHours: Double {
        Double(durationMinutes) / 60.0
    }
}

struct NowRoutinePlan: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var period: NowRoutinePeriod
    var startDate: Date
    var endDate: Date
    var blocks: [NowRoutineBlock]

    init(
        id: UUID = UUID(),
        period: NowRoutinePeriod,
        startDate: Date,
        endDate: Date,
        blocks: [NowRoutineBlock]
    ) {
        self.id = id
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.blocks = blocks
    }

    var title: String { period.title }
    var committedMinutes: Int { blocks.reduce(0) { $0 + $1.durationMinutes } }
}

struct NowWorkspacePreferences: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = currentSchemaVersion
    var allocationMode: NowAllocationMode = .percentage
    var weeklyBudgetHours: Double = 40
    var baselineNeeds: [BaselineNeed]
    var weeklyAllocations: [WeeklyAllocationPreset]
    var reflection: DailyReflectionSummary

    init(
        schemaVersion: Int = currentSchemaVersion,
        allocationMode: NowAllocationMode = .percentage,
        weeklyBudgetHours: Double = 40,
        baselineNeeds: [BaselineNeed] = NowWorkspacePreferences.defaultBaselineNeeds,
        weeklyAllocations: [WeeklyAllocationPreset] = NowWorkspacePreferences.defaultWeeklyAllocations,
        reflection: DailyReflectionSummary = .init()
    ) {
        self.schemaVersion = schemaVersion
        self.allocationMode = allocationMode
        self.weeklyBudgetHours = max(0, weeklyBudgetHours)
        self.baselineNeeds = baselineNeeds
        self.weeklyAllocations = weeklyAllocations
        self.reflection = reflection
    }

    static var defaultBaselineNeeds: [BaselineNeed] {
        [
            BaselineNeed(title: "Sleep", estimateMinutes: 8 * 60, notes: "A planning estimate, not a medical truth."),
            BaselineNeed(title: "Meals", estimateMinutes: 2 * 60, notes: "Time for eating and simple cleanup."),
            BaselineNeed(title: "Hygiene", estimateMinutes: 45, notes: "A daily care estimate, not a rule."),
            BaselineNeed(title: "Cleaning", estimateMinutes: 30, notes: "Light upkeep and resets."),
            BaselineNeed(title: "Errands", estimateMinutes: 60, notes: "Trips, pickups, and small logistics."),
            BaselineNeed(title: "Exercise", estimateMinutes: 45, notes: "Movement and recovery time."),
            BaselineNeed(title: "Family / personal care", estimateMinutes: 45, notes: "Relationship and care time."),
            BaselineNeed(title: "Other necessities", estimateMinutes: 30, notes: "Anything ordinary the day demands.")
        ]
    }

    static var defaultWeeklyAllocations: [WeeklyAllocationPreset] {
        [
            WeeklyAllocationPreset(
                title: "Professional brand",
                colorToken: .blue,
                percentage: 55,
                weeklyHours: 22,
                notes: "Dominant while portfolio closeout is still underway."
            ),
            WeeklyAllocationPreset(
                title: "TimeBite Apple release",
                colorToken: .green,
                percentage: 35,
                weeklyHours: 14,
                notes: "Dominant after portfolio closeout."
            ),
            WeeklyAllocationPreset(
                title: "Job search",
                colorToken: .gold,
                percentage: 1,
                weeklyHours: 0.5,
                notes: "Keep this minimal until evidence is ready."
            ),
            WeeklyAllocationPreset(
                title: "User-created project",
                colorToken: .violet,
                percentage: 0,
                weeklyHours: 0,
                notes: "Rename this lane for anything else you want to protect."
            )
        ]
    }
}
