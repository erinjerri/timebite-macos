#if canImport(XCTest)
import XCTest
@testable import timebite_macos

@MainActor
final class NowWorkspaceTests: XCTestCase {
    func testTimerExpirationDoesNotAutoCompleteAction() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var current = start

        let action = Action(goalID: nil, projectID: nil, title: "Write homepage copy", estimatedDuration: 5 * 60, status: .planned)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let model = NowWorkspaceViewModel(repository: repository, now: { current })

        model.start(action)
        current = start.addingTimeInterval(6 * 60)

        XCTAssertEqual(model.timerStatusText(for: action, now: current), "Timer expired")
        XCTAssertEqual(model.activeSession?.status, .active)

        let savedActions = try repository.actions()
        XCTAssertEqual(savedActions.first?.status, .planned)
    }

    func testExplicitCompletionMarksActionComplete() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var current = start

        let action = Action(goalID: nil, projectID: nil, title: "Write homepage copy", estimatedDuration: 45 * 60, status: .planned)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let model = NowWorkspaceViewModel(repository: repository, now: { current })

        model.start(action)
        current = start.addingTimeInterval(10 * 60)
        model.markComplete(action)

        let savedSessions = try repository.focusSessions()
        XCTAssertEqual(savedSessions.count, 1)
        XCTAssertEqual(savedSessions.first?.status, .completed)
        XCTAssertEqual(Int(savedSessions.first?.actualDuration ?? 0), 600)

        let savedActions = try repository.actions()
        XCTAssertEqual(savedActions.first?.status, .completed)
    }

    func testClearTimerCancelsSessionWithoutCompletingAction() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var current = start

        let action = Action(goalID: nil, projectID: nil, title: "Write homepage copy", estimatedDuration: 45 * 60, status: .planned)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let model = NowWorkspaceViewModel(repository: repository, now: { current })

        model.start(action)
        current = start.addingTimeInterval(4 * 60)
        model.clearActiveSession()

        let savedSessions = try repository.focusSessions()
        XCTAssertEqual(savedSessions.count, 1)
        XCTAssertEqual(savedSessions.first?.status, .cancelled)
        XCTAssertEqual(Int(savedSessions.first?.actualDuration ?? -1), 0)

        let savedActions = try repository.actions()
        XCTAssertEqual(savedActions.first?.status, .planned)
    }

    func testInvalidEstimateRangeIsRejected() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let repository = InMemoryPlanningRepository(store: PlanningStore())
        let model = NowWorkspaceViewModel(repository: repository, now: { now })

        model.draftActionTitle = "Plan a route"
        model.draftEstimateInputMode = .timeRange
        model.draftEstimateStartDate = now.addingTimeInterval(2 * 3_600)
        model.draftEstimateEndDate = now.addingTimeInterval(3_600)

        model.createAction()

        XCTAssertEqual(model.errorMessage, "Estimated end time must be after the start time.")
        XCTAssertTrue((try repository.actions()).isEmpty)
    }

    func testSleepEntryUpdatesDailyBaselineWithoutChangingPreferences() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let repository = InMemoryPlanningRepository(store: PlanningStore())
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let model = NowWorkspaceViewModel(
            repository: repository,
            dailyEntryStore: LocalNowDailyEntryStore(defaults: defaults),
            now: { now }
        )

        XCTAssertTrue(model.isSleepPromptVisible)

        let defaultBaseline = model.dailyLanes(now: now).first?.plannedMinutes ?? 0
        model.setSleepMinutes(6 * 60)
        let adjustedBaseline = model.dailyLanes(now: now).first?.plannedMinutes ?? 0

        XCTAssertFalse(model.isSleepPromptVisible)
        XCTAssertEqual(defaultBaseline - adjustedBaseline, 2 * 60)
    }

    func testQuickCaptureParsesBatchedActions() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let repository = InMemoryPlanningRepository(store: PlanningStore())
        let model = NowWorkspaceViewModel(repository: repository, now: { now })

        model.captureQuickActions(from: """
        - Review notes
        1. Merge branch
        • Send update
        """)

        let savedActions = try repository.actions()
        XCTAssertEqual(savedActions.map(\.title), ["Review notes", "Merge branch", "Send update"])
        XCTAssertEqual(savedActions.first?.status, .inbox)
    }
}
#endif
