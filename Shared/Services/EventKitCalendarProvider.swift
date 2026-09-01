#if canImport(EventKit)
import EventKit
import Foundation

@MainActor
final class EventKitCalendarProvider: ExternalCalendarProviding {
    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    var authorizationState: CalendarAuthorizationState {
        if #available(macOS 14, *) {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined: .notDetermined
            case .fullAccess, .writeOnly: .authorized
            case .authorized: .authorized
            case .denied: .denied
            case .restricted: .restricted
            @unknown default: .unavailable
            }
        } else {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined: .notDetermined
            case .authorized: .authorized
            case .denied: .denied
            case .restricted: .restricted
            default: .unavailable
            }
        }
    }

    func requestAccess() async -> CalendarAuthorizationState {
        do {
            return try await eventStore.requestFullAccessToEvents() ? .authorized : .denied
        } catch {
            return .unavailable
        }
    }

    func events(in interval: DateInterval) async throws -> [ExternalCalendarEvent] {
        guard authorizationState == .authorized else { throw ExternalCalendarError.permissionDenied }
        let predicate = eventStore.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
        return eventStore.events(matching: predicate).map { event in
            ExternalCalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                calendarID: event.calendar.calendarIdentifier,
                title: event.title ?? "Untitled event",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay
            )
        }
    }
}

@MainActor
final class EventKitCalendarWriter: ExternalCalendarWriting {
    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    func createEvent(title: String, startDate: Date, endDate: Date, notes: String?) async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .fullAccess || status == .writeOnly else {
            throw ExternalCalendarError.permissionDenied
        }
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent, commit: true)
    }
}
#endif
