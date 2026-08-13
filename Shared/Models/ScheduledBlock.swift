import Foundation

enum ScheduledBlockStatus: String, CaseIterable, Codable, Sendable {
    case planned
    case active
    case completed
    case skipped
    case cancelled
}

enum CalendarSource: String, CaseIterable, Codable, Sendable {
    case timeBite
    case appleCalendar
    case imported
}

struct ScheduledBlock: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var actionID: UUID?
    var goalID: UUID?
    var title: String
    var startDate: Date
    var endDate: Date
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var status: ScheduledBlockStatus
    var calendarSource: CalendarSource
    var externalCalendarID: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        actionID: UUID? = nil,
        goalID: UUID? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        plannedDuration: TimeInterval? = nil,
        actualDuration: TimeInterval? = nil,
        status: ScheduledBlockStatus = .planned,
        calendarSource: CalendarSource = .timeBite,
        externalCalendarID: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let interval = max(0, plannedDuration ?? endDate.timeIntervalSince(startDate))
        self.id = id
        self.actionID = actionID
        self.goalID = goalID
        self.title = title
        self.startDate = startDate
        self.endDate = startDate.addingTimeInterval(interval)
        self.plannedDuration = interval
        self.actualDuration = actualDuration.map { max(0, $0) }
        self.status = status
        self.calendarSource = calendarSource
        self.externalCalendarID = externalCalendarID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func move(to newStartDate: Date, updatedAt: Date = Date()) {
        startDate = newStartDate
        endDate = newStartDate.addingTimeInterval(plannedDuration)
        self.updatedAt = updatedAt
    }

    mutating func resize(to newEndDate: Date, updatedAt: Date = Date()) {
        endDate = max(newEndDate, startDate)
        plannedDuration = endDate.timeIntervalSince(startDate)
        self.updatedAt = updatedAt
    }

    mutating func complete(actualDuration: TimeInterval? = nil, updatedAt: Date = Date()) {
        status = .completed
        self.actualDuration = actualDuration.map { max(0, $0) }
        self.updatedAt = updatedAt
    }
}
