#if canImport(XCTest)
import XCTest
@testable import timebite_macos

final class PlanningDomainTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testActionCanExistWithNoScheduledBlocks() throws {
        let repository = InMemoryPlanningRepository()
        let action = Action(title: "Inbox thought")
        try repository.save(action)
        XCTAssertEqual(try repository.actions(), [action])
        XCTAssertTrue(try repository.scheduledBlocks().isEmpty)
        XCTAssertNil(action.goalID)
        XCTAssertNil(action.milestoneID)
        XCTAssertNil(action.projectID)
    }

    func testActionCanHaveOneScheduledBlock() throws {
        let repository = InMemoryPlanningRepository()
        let action = Action(title: "Build Track UI", estimatedDuration: 3600)
        let block = SchedulingService().schedule(action: action, at: start)
        try repository.save(action)
        try repository.save(block)
        XCTAssertEqual(try repository.scheduledBlocks().count, 1)
        XCTAssertEqual(block.actionID, action.id)
        XCTAssertEqual(block.plannedDuration, 3600)
        XCTAssertEqual(block.endDate, start.addingTimeInterval(3600))
    }

    func testActionCanHaveMultipleScheduledBlocks() throws {
        let action = Action(title: "Build Track UI", estimatedDuration: 3600)
        let service = SchedulingService()
        let starts = [start, start.addingTimeInterval(86_400), start.addingTimeInterval(172_800)]
        let blocks = starts.map { service.schedule(action: action, at: $0) }
        XCTAssertEqual(Set(blocks.compactMap(\.actionID)), [action.id])
        XCTAssertEqual(Set(blocks.map(\.id)).count, 3)
    }

    func testDeletingBlockPreservesAction() throws {
        let repository = InMemoryPlanningRepository()
        let action = Action(title: "Build Track UI")
        let block = SchedulingService().schedule(action: action, at: start)
        try repository.save(action)
        try repository.save(block)
        try repository.deleteScheduledBlock(id: block.id)
        XCTAssertTrue(try repository.scheduledBlocks().isEmpty)
        XCTAssertEqual(try repository.actions(), [action])
    }

    func testResizingBlockChangesPlannedDuration() {
        var block = ScheduledBlock(title: "Work", startDate: start, endDate: start.addingTimeInterval(1800))
        block.resize(to: start.addingTimeInterval(5400))
        XCTAssertEqual(block.plannedDuration, 5400)
        XCTAssertEqual(block.endDate, start.addingTimeInterval(5400))
    }

    func testMovingBlockChangesDatesAndPreservesDuration() {
        var block = ScheduledBlock(title: "Work", startDate: start, endDate: start.addingTimeInterval(3600))
        let movedStart = start.addingTimeInterval(86_400)
        block.move(to: movedStart)
        XCTAssertEqual(block.startDate, movedStart)
        XCTAssertEqual(block.endDate, movedStart.addingTimeInterval(3600))
        XCTAssertEqual(block.plannedDuration, 3600)
    }

    func testCompletingBlockDoesNotCompleteAction() {
        let action = Action(title: "Build Track UI", status: .inProgress)
        var block = SchedulingService().schedule(action: action, at: start)
        block.complete(actualDuration: 2400)
        XCTAssertEqual(block.status, .completed)
        XCTAssertEqual(block.actualDuration, 2400)
        XCTAssertFalse(action.isCompleted)
    }

    func testGoalMilestoneProjectRelationshipsRemainExplicit() {
        let goal = Goal(title: "Ship TimeBite")
        let milestone = Milestone(goalID: goal.id, title: "Planning foundation")
        let project = Project(goalID: goal.id, milestoneID: milestone.id, title: "macOS Plan")
        let action = Action(goalID: goal.id, milestoneID: milestone.id, projectID: project.id, title: "Define blocks")
        XCTAssertEqual(milestone.goalID, goal.id)
        XCTAssertEqual(project.milestoneID, milestone.id)
        XCTAssertEqual(action.projectID, project.id)
    }

    func testExternalCalendarRepresentationRemainsSeparate() throws {
        let repository = InMemoryPlanningRepository()
        let block = ScheduledBlock(title: "TimeBite", startDate: start, endDate: start.addingTimeInterval(1800))
        let event = ExternalCalendarEvent(id: "event-1", calendarID: "work", title: "External meeting", startDate: start, endDate: start.addingTimeInterval(3600), isAllDay: false)
        try repository.save(block)
        let items = CalendarItemAdapter().merge(
            blocks: try repository.scheduledBlocks(),
            externalEvents: [event],
            in: DateInterval(start: start.addingTimeInterval(-1), end: start.addingTimeInterval(7200))
        )
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(try repository.scheduledBlocks(), [block])
        guard case .externalEvent(let representedEvent) = items.first(where: { $0.title == event.title }) else {
            return XCTFail("Expected a separate external event calendar item")
        }
        XCTAssertEqual(representedEvent.id, event.id)
    }

    func testLocalRepositoryPersistsScheduledBlockWithoutSwiftDataMigration() throws {
        let suiteName = "PlanningDomainTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let block = ScheduledBlock(title: "Persisted block", startDate: start, endDate: start.addingTimeInterval(1800))
        try LocalPlanningRepository(defaults: defaults).save(block)
        XCTAssertEqual(try LocalPlanningRepository(defaults: defaults).scheduledBlocks(), [block])
    }

    func testCentralDefaultDurationIsUsedWhenActionHasNoEstimate() {
        let action = Action(title: "Unestimated action")
        let block = SchedulingService().schedule(action: action, at: start)
        XCTAssertEqual(block.plannedDuration, SchedulingDefaults.defaultBlockDuration)
    }
}
#endif
