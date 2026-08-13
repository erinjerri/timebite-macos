import Foundation

struct ExternalCalendarEvent: Identifiable, Hashable, Sendable {
    var id: String
    var calendarID: String
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
}

enum CalendarItem: Identifiable, Hashable, Sendable {
    case timeBiteBlock(ScheduledBlock)
    case externalEvent(ExternalCalendarEvent)

    var id: String {
        switch self {
        case .timeBiteBlock(let block): "timebite-\(block.id.uuidString)"
        case .externalEvent(let event): "external-\(event.calendarID)-\(event.id)"
        }
    }

    var title: String {
        switch self {
        case .timeBiteBlock(let block): block.title
        case .externalEvent(let event): event.title
        }
    }

    var startDate: Date {
        switch self {
        case .timeBiteBlock(let block): block.startDate
        case .externalEvent(let event): event.startDate
        }
    }

    var endDate: Date {
        switch self {
        case .timeBiteBlock(let block): block.endDate
        case .externalEvent(let event): event.endDate
        }
    }
}
