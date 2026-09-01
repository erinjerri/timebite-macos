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

    func testBulkCaptureParserProducesCandidatesWithPreservedSourceText() {
        let text = """
        - Draft launch plan
        Work:
        * grocery pickup after meeting
        """
        let result = BulkCaptureParser().parse(text)
        XCTAssertEqual(result.originalText, text)
        XCTAssertEqual(result.candidates.count, 3)
        XCTAssertEqual(result.candidates[0].title, "Draft launch plan")
        XCTAssertEqual(result.candidates[1].kind, .heading)
        XCTAssertEqual(result.candidates[2].lifeArea, .errands)
    }

    func testEstimateAdjustmentRepositoryLearnsCorrectionsLocally() {
        let suiteName = "PlanningDomainTests.estimates.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repo = LocalEstimateAdjustmentRepository(defaults: defaults)
        repo.record(inputMinutes: 45, correctedMinutes: 60)
        XCTAssertEqual(repo.adjustedEstimate(for: 45), 60)
    }

    func testCalendarPlanningServiceSkipsFixedEventsWhenSuggestingBlocks() {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        let event = ExternalCalendarEvent(id: "event", calendarID: "work", title: "Performance", startDate: day.addingTimeInterval(4 * 3_600), endDate: day.addingTimeInterval(5 * 3_600), isAllDay: false)
        let actions = [
            Action(title: "Deep work", estimatedDuration: 3_600),
            Action(title: "Errand", estimatedDuration: 1_800)
        ]
        let service = CalendarPlanningService(calendar: calendar, availabilityWindow: DateInterval(start: day, end: day.addingTimeInterval(8 * 3_600)), fixedEvents: [event])
        let suggestions = service.suggest(actions: actions, estimateRepository: LocalEstimateAdjustmentRepository(defaults: UserDefaults(suiteName: "PlanningDomainTests.suggestions.\(UUID().uuidString)")!))
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.block.endDate <= event.startDate || $0.block.startDate >= event.endDate })
    }

    func testDogfoodSeedDataBuildsACompleteHierarchy() {
        let goals = DogfoodSeedData.makeGoals()
        let milestones = DogfoodSeedData.makeMilestones()
        let projects = DogfoodSeedData.makeProjects()
        let actions = DogfoodSeedData.makeActions()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(milestones.count, 5)
        XCTAssertEqual(projects.count, 6)
        XCTAssertEqual(actions.count, 26)

        let goalID = goals.first?.id
        XCTAssertTrue(milestones.allSatisfy { $0.goalID == goalID })
        XCTAssertTrue(projects.allSatisfy { $0.goalID == goalID })
        XCTAssertTrue(actions.allSatisfy { $0.goalID == goalID })

        let milestoneIDs = Set(milestones.map(\.id))
        let projectIDs = Set(projects.map(\.id))
        XCTAssertTrue(projects.allSatisfy { $0.milestoneID.map { milestoneIDs.contains($0) } ?? false })
        XCTAssertTrue(actions.allSatisfy { $0.milestoneID.map { milestoneIDs.contains($0) } ?? false })
        XCTAssertTrue(actions.allSatisfy { $0.projectID.map { projectIDs.contains($0) } ?? false })
        XCTAssertTrue(actions.allSatisfy { $0.lifeAreaID != nil })
    }

    func testDogfoodSeedDataHasNoDuplicateUUIDs() {
        let ids = DogfoodSeedData.makeGoals().map(\.id)
            + DogfoodSeedData.makeMilestones().map(\.id)
            + DogfoodSeedData.makeProjects().map(\.id)
            + DogfoodSeedData.makeActions().map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testDogfoodSeedDataSeedsIdempotently() throws {
        let repository = InMemoryPlanningRepository()

        try DogfoodSeedData.seed(into: repository)
        let firstCounts = try currentSeedCounts(in: repository)

        try DogfoodSeedData.seed(into: repository)
        let secondCounts = try currentSeedCounts(in: repository)

        XCTAssertEqual(firstCounts, secondCounts)
    }

    func testDogfoodSeedDataUsesDurationsAndPrioritiesForEveryAction() {
        let actions = DogfoodSeedData.makeActions()

        XCTAssertTrue(actions.allSatisfy { $0.estimatedDuration != nil })
        XCTAssertTrue(actions.allSatisfy { $0.priority != nil })
    }

    func testDogfoodSeedDataMatchesPlannedAndInboxMinutes() {
        let actions = DogfoodSeedData.makeActions()

        let plannedMinutes = minutes(for: actions.filter { $0.status == .planned })
        let inboxMinutes = minutes(for: actions.filter { $0.status == .inbox })
        let dayOneMinutes = minutes(for: actions.filter { $0.status == .planned && $0.startDate == startOfToday })
        let completedCount = actions.filter { $0.status == .completed }.count
        let completedStartDate = actions.first(where: { $0.status == .completed })?.startDate

        XCTAssertEqual(plannedMinutes, 435)
        XCTAssertEqual(inboxMinutes, 55)
        XCTAssertEqual(dayOneMinutes, 255)
        XCTAssertEqual(completedCount, 1)
        XCTAssertTrue((completedStartDate ?? Date.distantPast) < startOfToday)
    }

    func testPlanningCaptureParserBuildsPlanningItems() {
        let text = """
        1. Core platform rebuild
        - urgent launch prep
        Blocked vendor follow-up
        """

        let items = PlanningCaptureParser.parseProjects(from: text, calendar: .current)

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.first?.title, "Core platform rebuild")
        XCTAssertEqual(items[1].priority, .urgent)
        XCTAssertEqual(items[2].boardState, .blocked)
    }

    func testPlanningCaptureSummaryEncodesProjects() {
        let summary = PlanningCaptureSummary(
            recognizedText: "1. Pilot",
            projects: [PlanningCaptureProject(title: "Pilot", notes: "", priority: "medium", boardState: "backlog")]
        )

        XCTAssertTrue(summary.jsonString.contains("\"Pilot\""))
    }

    func testDogfoodSeedDataKeepsInboxActionsUnscheduled() {
        let inboxActions = DogfoodSeedData.makeActions().filter { $0.status == .inbox }

        XCTAssertTrue(inboxActions.allSatisfy { $0.startDate == nil })
    }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private func currentSeedCounts(in repository: InMemoryPlanningRepository) throws -> [Int] {
        [
            try repository.goals().count,
            try repository.milestones().count,
            try repository.projects().count,
            try repository.actions().count
        ]
    }

    private func minutes(for actions: [Action]) -> Int {
        actions.reduce(0) { partialResult, action in
            partialResult + Int((action.estimatedDuration ?? 0) / 60)
        }
    }
}
#endif
