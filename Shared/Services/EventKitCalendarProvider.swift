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
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .fullAccess, .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .writeOnly: .denied
        @unknown default: .unavailable
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
#endif
