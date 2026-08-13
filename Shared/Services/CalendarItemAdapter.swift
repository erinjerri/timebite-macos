import Foundation

protocol ExternalCalendarProviding {
    var authorizationState: CalendarAuthorizationState { get }
    func requestAccess() async -> CalendarAuthorizationState
    func events(in interval: DateInterval) async throws -> [ExternalCalendarEvent]
}

enum CalendarAuthorizationState: String, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

enum ExternalCalendarError: Error {
    case permissionDenied
}

struct ExternalCalendarLoadResult: Equatable, Sendable {
    var authorizationState: CalendarAuthorizationState
    var events: [ExternalCalendarEvent]
}

struct CalendarExternalEventService {
    func load(
        from provider: any ExternalCalendarProviding,
        in interval: DateInterval,
        requestAccess: Bool
    ) async -> ExternalCalendarLoadResult {
        var state = provider.authorizationState
        if state == .notDetermined, requestAccess {
            state = await provider.requestAccess()
        }
        guard state == .authorized else {
            return ExternalCalendarLoadResult(authorizationState: state, events: [])
        }
        do {
            return ExternalCalendarLoadResult(
                authorizationState: state,
                events: try await provider.events(in: interval)
            )
        } catch {
            return ExternalCalendarLoadResult(authorizationState: .unavailable, events: [])
        }
    }
}

struct CalendarItemAdapter {
    func merge(
        blocks: [ScheduledBlock],
        externalEvents: [ExternalCalendarEvent],
        in interval: DateInterval
    ) -> [CalendarItem] {
        let blockItems = blocks
            .filter { $0.endDate > interval.start && $0.startDate < interval.end }
            .map(CalendarItem.timeBiteBlock)
        let eventItems = externalEvents
            .filter { $0.endDate > interval.start && $0.startDate < interval.end }
            .map(CalendarItem.externalEvent)
        return (blockItems + eventItems).sorted {
            if $0.startDate == $1.startDate { return $0.title < $1.title }
            return $0.startDate < $1.startDate
        }
    }
}
