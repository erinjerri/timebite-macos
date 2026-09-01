#if canImport(XCTest)
import XCTest
@testable import timebite_macos

@MainActor
final class NowWorkspaceTests: XCTestCase {
    func testTimerSessionPersistsActualDurationAndPartialCompletion() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var current = start

        let action = Action(goalID: nil, projectID: nil, title: "Write homepage copy", estimatedDuration: 45 * 60, status: .planned)
        let repository = InMemoryPlanningRepository(store: PlanningStore(actions: [action]))
        let model = NowWorkspaceViewModel(repository: repository, now: { current })

        model.start(action)
        current = start.addingTimeInterval(600)
        model.completionChoice = .keepInProgress
        model.stopActiveSession()

        let savedSessions = try repository.focusSessions()
        XCTAssertEqual(savedSessions.count, 1)
        XCTAssertEqual(savedSessions.first?.status, .completed)
        XCTAssertEqual(Int(savedSessions.first?.actualDuration ?? 0), 600)

        let savedActions = try repository.actions()
        XCTAssertEqual(savedActions.first?.status, .inProgress)
    }
}
#endif
