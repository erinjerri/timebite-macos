#if canImport(XCTest)
import XCTest
@testable import timebite_macos

@MainActor
final class CalendarFeatureTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testDropActionCreatesScheduledBlockWithCorrectActionIDAndEstimate() throws {
        let action = Action(title: "Track UI", estimatedDuration: 5400)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let block = try CalendarSchedulingService(repository: repository).dropAction(id: action.id, at: start)
        XCTAssertEqual(block.actionID, action.id)
        XCTAssertEqual(block.plannedDuration, 5400)
        XCTAssertEqual(block.endDate, start.addingTimeInterval(5400))
        XCTAssertEqual(try repository.scheduledBlocks(), [block])
    }

    func testDropUsesCentralFallbackDuration() throws {
        let action = Action(title: "No estimate")
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let block = try CalendarSchedulingService(repository: repository).dropAction(id: action.id, at: start)
        XCTAssertEqual(block.plannedDuration, SchedulingDefaults.defaultBlockDuration)
    }

    func testMoveBlockChangesDayAndTime() throws {
        let action = Action(title: "Move me", estimatedDuration: 3600)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let service = CalendarSchedulingService(repository: repository)
        let block = try service.dropAction(id: action.id, at: start)
        let destination = start.addingTimeInterval(90_000)
        let moved = try service.moveBlock(id: block.id, to: destination)
        XCTAssertEqual(moved.startDate, destination)
        XCTAssertEqual(moved.endDate, destination.addingTimeInterval(3600))
    }

    func testResizeBlockChangesPlannedDuration() throws {
        let action = Action(title: "Resize me", estimatedDuration: 1800)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let service = CalendarSchedulingService(repository: repository)
        let block = try service.dropAction(id: action.id, at: start)
        let resized = try service.resizeBlock(id: block.id, to: start.addingTimeInterval(7200))
        XCTAssertEqual(resized.plannedDuration, 7200)
    }

    func testDeleteBlockPreservesAction() throws {
        let action = Action(title: "Keep me")
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let service = CalendarSchedulingService(repository: repository)
        let block = try service.dropAction(id: action.id, at: start)
        try service.deleteBlock(id: block.id)
        XCTAssertTrue(try repository.scheduledBlocks().isEmpty)
        XCTAssertEqual(try repository.actions(), [action])
    }

    func testSameActionCanCreateMultipleBlocks() throws {
        let action = Action(title: "Multi-session", estimatedDuration: 3600)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let service = CalendarSchedulingService(repository: repository)
        try service.dropAction(id: action.id, at: start)
        try service.dropAction(id: action.id, at: start.addingTimeInterval(86_400))
        try service.dropAction(id: action.id, at: start.addingTimeInterval(172_800))
        XCTAssertEqual(try repository.scheduledBlocks().count, 3)
        XCTAssertTrue(try repository.scheduledBlocks().allSatisfy { $0.actionID == action.id })
    }

    func testPermissionDeniedReturnsNoExternalEvents() async {
        let provider = DeniedCalendarProvider()
        let interval = DateInterval(start: start, duration: 86_400)
        let result = await CalendarExternalEventService().load(from: provider, in: interval, requestAccess: true)
        XCTAssertEqual(result.authorizationState, .denied)
        XCTAssertTrue(result.events.isEmpty)
        XCTAssertFalse(provider.eventsWereRequested)
    }

    func testExternalEventsDoNotBecomeActions() async throws {
        let action = Action(title: "TimeBite action")
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let event = ExternalCalendarEvent(id: "event", calendarID: "calendar", title: "External", startDate: start, endDate: start.addingTimeInterval(3600), isAllDay: false)
        let provider = AuthorizedCalendarProvider(events: [event])
        let interval = DateInterval(start: start.addingTimeInterval(-1), duration: 7200)
        let result = await CalendarExternalEventService().load(from: provider, in: interval, requestAccess: false)
        XCTAssertEqual(result.events, [event])
        XCTAssertEqual(try repository.actions(), [action])
        XCTAssertTrue(try repository.scheduledBlocks().isEmpty)
    }
}

@MainActor
private final class DeniedCalendarProvider: ExternalCalendarProviding {
    var eventsWereRequested = false
    var authorizationState: CalendarAuthorizationState { .notDetermined }
    func requestAccess() async -> CalendarAuthorizationState { .denied }
    func events(in interval: DateInterval) async throws -> [ExternalCalendarEvent] {
        eventsWereRequested = true
        return []
    }
}

@MainActor
private final class AuthorizedCalendarProvider: ExternalCalendarProviding {
    let suppliedEvents: [ExternalCalendarEvent]
    init(events: [ExternalCalendarEvent]) { suppliedEvents = events }
    var authorizationState: CalendarAuthorizationState { .authorized }
    func requestAccess() async -> CalendarAuthorizationState { .authorized }
    func events(in interval: DateInterval) async throws -> [ExternalCalendarEvent] { suppliedEvents }
}
#endif
