#if canImport(XCTest)
import XCTest
@testable import timebite_macos

@MainActor
final class TimelineDashboardTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testTimelineHierarchyUsesExistingDomainRelationships() throws {
        let goal = Goal(title: "Goal", startDate: start, targetDate: start.addingTimeInterval(10 * 86_400))
        let milestone = Milestone(goalID: goal.id, title: "Milestone")
        let project = Project(goalID: goal.id, milestoneID: milestone.id, title: "Project")
        let action = Action(goalID: goal.id, milestoneID: milestone.id, projectID: project.id, title: "Action")
        let repository = InMemoryPlanningRepository(store: PlanningStore(goals: [goal], milestones: [milestone], projects: [project], actions: [action]))

        let hierarchy = try TimelineService(repository: repository).hierarchy()

        XCTAssertEqual(hierarchy.count, 1)
        XCTAssertEqual(hierarchy[0].id, .goal(goal.id))
        XCTAssertEqual(hierarchy[0].children[0].id, .milestone(milestone.id))
        XCTAssertEqual(hierarchy[0].children[0].children[0].id, .project(project.id))
        XCTAssertEqual(hierarchy[0].children[0].children[0].children[0].id, .action(action.id))
    }

    func testMovingTimelineItemUpdatesUnderlyingEntityDates() throws {
        let project = Project(title: "Project", startDate: start, targetDate: start.addingTimeInterval(5 * 86_400))
        let repository = InMemoryPlanningRepository(store: PlanningStore(projects: [project]))

        try TimelineService(repository: repository).move(.project(project.id), byDays: 3, calendar: calendar)

        let updated = try XCTUnwrap(repository.projects().first)
        XCTAssertEqual(updated.startDate, calendar.date(byAdding: .day, value: 3, to: start))
        XCTAssertEqual(updated.targetDate, calendar.date(byAdding: .day, value: 8, to: start))
    }

    func testResizingTimelineItemUpdatesUnderlyingDateRange() throws {
        let action = Action(title: "Action", startDate: start, targetDate: start.addingTimeInterval(5 * 86_400))
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let service = TimelineService(repository: repository)
        let newStart = start.addingTimeInterval(86_400)
        let newTarget = start.addingTimeInterval(9 * 86_400)

        try service.resizeStart(.action(action.id), to: newStart)
        try service.resizeTarget(.action(action.id), to: newTarget)

        let updated = try XCTUnwrap(repository.actions().first)
        XCTAssertEqual(updated.startDate, newStart)
        XCTAssertEqual(updated.targetDate, newTarget)
    }

    func testDashboardProgressAggregationIsDeterministicAndClamped() throws {
        let category = ActivityCategory(id: "career", title: "Career")
        let record = DailyTrackingRecord(
            date: start,
            activities: [TrackedActivity(date: start, title: "Build", category: category, duration: 5_400, plannedDuration: 3_600)]
        )

        let metrics = DashboardAggregationService().metrics(
            range: .sevenDays, endingAt: start, records: [record], habits: [], habitLogs: [], actions: [],
            scheduledBlocks: [], focusSessions: [], calendar: calendar
        )

        XCTAssertEqual(metrics.series.count, 1)
        XCTAssertEqual(metrics.series[0].seriesID, "career")
        XCTAssertEqual(metrics.series[0].normalizedValue, 1)
    }

    func testDashboardMissingInputsDoNotCreateScore() {
        let metrics = DashboardAggregationService().metrics(
            range: .thirtyDays, endingAt: start, records: [], habits: [], habitLogs: [], actions: [],
            scheduledBlocks: [], focusSessions: [], calendar: calendar
        )
        XCTAssertFalse(metrics.hasData)
        XCTAssertTrue(metrics.series.isEmpty)
        XCTAssertTrue(metrics.components.isEmpty)
    }

    func testDashboardRangeIsBoundedToRequestedDays() {
        let metrics = DashboardAggregationService().metrics(
            range: .threeMonths, endingAt: start, records: [], habits: [], habitLogs: [], actions: [],
            scheduledBlocks: [], focusSessions: [], calendar: calendar
        )
        XCTAssertEqual(calendar.dateComponents([.day], from: metrics.interval.start, to: metrics.interval.end).day, 90)
    }

    func testPlannedVsActualUsesBlocksAndCompletedFocusSessions() throws {
        let block = ScheduledBlock(title: "Plan", startDate: start, endDate: start.addingTimeInterval(3_600))
        let session = FocusSession(scheduledBlockID: block.id, startDate: start, endDate: start.addingTimeInterval(1_800), actualDuration: 1_800, status: .completed)
        let metrics = DashboardAggregationService().metrics(
            range: .sevenDays, endingAt: start, records: [], habits: [], habitLogs: [], actions: [],
            scheduledBlocks: [block], focusSessions: [session], calendar: calendar
        )
        let component = try XCTUnwrap(metrics.components.first(where: { $0.id == "planned-actual" }))
        XCTAssertEqual(component.value, 0.5)
        XCTAssertEqual(metrics.plannedFocusTime, 3_600)
        XCTAssertEqual(metrics.actualFocusTime, 1_800)
    }

    func testHiddenAndSelectedSeriesRemainPresentationState() throws {
        let tracking = PreviewTrackingRepository.dashboard(relativeTo: start, calendar: calendar)
        let viewModel = DashboardViewModel(
            planningRepository: InMemoryPlanningRepository(),
            trackingRepository: tracking,
            habitRepository: tracking,
            calendar: calendar,
            now: { self.start }
        )
        let series = try XCTUnwrap(viewModel.series.first)
        XCTAssertTrue(viewModel.visibleSeriesIDs.contains(series.id))

        viewModel.toggleSeries(series.id)
        XCTAssertFalse(viewModel.visibleSeriesIDs.contains(series.id))
        XCTAssertFalse(viewModel.visiblePoints.contains(where: { $0.seriesID == series.id }))
        XCTAssertTrue(viewModel.metrics.series.contains(where: { $0.seriesID == series.id }))

        viewModel.selectedDate = start
        XCTAssertTrue(viewModel.selectedPoints.allSatisfy { calendar.isDate($0.date, inSameDayAs: start) })
    }
}
#endif
