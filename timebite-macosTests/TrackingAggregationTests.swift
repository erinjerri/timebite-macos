#if canImport(XCTest)
import XCTest
@testable import timebite_macos

final class TrackingAggregationTests: XCTestCase {
    private let calculator = HabitCompletionCalculator()
    private let service = TrackingAggregationService()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    func testBooleanHabitCompletion() {
        let habit = Habit(title: "Morning pages", trackingType: .boolean)
        XCTAssertEqual(calculator.normalizedProgress(for: habit, value: 0), 0)
        XCTAssertEqual(calculator.normalizedProgress(for: habit, value: 1), 1)
    }

    func testCountHabitCompletion() {
        let habit = Habit(title: "Read", trackingType: .count, targetValue: 20, unit: "pages")
        XCTAssertEqual(calculator.normalizedProgress(for: habit, value: 10), 0.5)
    }

    func testDurationHabitCompletion() {
        let habit = Habit(title: "Meditate", trackingType: .duration, targetValue: 15, unit: "minutes")
        XCTAssertEqual(calculator.normalizedProgress(for: habit, value: 15), 1)
    }

    func testQuantityHabitCompletionClamps() {
        let habit = Habit(title: "Walk", trackingType: .quantity, targetValue: 10_000, unit: "steps")
        XCTAssertEqual(calculator.normalizedProgress(for: habit, value: 12_000), 1)
    }

    func testDailyAggregationUsesSupportedInputs() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let activity = TrackedActivity(date: date, title: "Focus", category: .init(id: "focus", title: "Focus"), duration: 1800)
        let record = DailyTrackingRecord(
            date: date,
            plannedActions: 8,
            completedActions: 4,
            goalLinkedActions: 2,
            completedGoalLinkedActions: 1,
            plannedFocusTime: 3600,
            activities: [activity],
            reflectionCompleted: true
        )
        let result = service.daily(record: record, date: date, calendar: calendar)
        XCTAssertEqual(result.alignment.focus, 0.5)
        XCTAssertEqual(result.alignment.actions, 0.5)
        XCTAssertEqual(result.alignment.goals, 0.5)
        XCTAssertEqual(result.alignment.reflection, 1)
        XCTAssertEqual(result.alignment.overall, 0.625)
    }

    func testWeeklyAggregationUsesDailyRecords() {
        let monday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))!
        let activity = TrackedActivity(date: monday, title: "Focus", category: .init(id: "work", title: "Work"), duration: 3600)
        let record = DailyTrackingRecord(date: monday, plannedActions: 2, completedActions: 2, plannedFocusTime: 3600, activities: [activity])
        let result = service.weekly(records: [record], containing: monday, calendar: calendar)
        XCTAssertEqual(result.days.count, 7)
        XCTAssertEqual(result.totalFocusTime, 3600)
        XCTAssertEqual(result.completedActions, 2)
        XCTAssertTrue(result.hasData)
    }

    func testMonthlyAggregationDoesNotFabricateUnsupportedMetrics() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))!
        let record = DailyTrackingRecord(date: date, plannedActions: 1, completedActions: 1)
        let result = service.monthly(records: [record], containing: date, calendar: calendar)
        XCTAssertNotNil(result.alignment)
        XCTAssertNil(result.completedGoals)
        XCTAssertNil(result.completedMilestones)
    }

    func testNoDataBehavior() {
        let result = service.daily(record: nil, date: Date(), calendar: calendar)
        XCTAssertFalse(result.hasData)
        XCTAssertEqual(result.alignment.overall, 0)
        XCTAssertTrue(result.activities.isEmpty)
    }

    func testMonthlyCheckmarkThresholds() {
        XCTAssertEqual(TrackingThresholds.state(for: 0.8), .achieved)
        XCTAssertEqual(TrackingThresholds.state(for: 0.4), .partial)
        XCTAssertEqual(TrackingThresholds.state(for: nil), .noData)
        XCTAssertEqual(TrackingThresholds.state(for: 0), .noData)
    }

    func testHabitCanLinkToGoalWithoutRequiringOne() {
        let goalID = UUID()
        let linked = Habit(title: "Write", goalID: goalID, trackingType: .duration, targetValue: 30)
        let unlinked = Habit(title: "Stretch", trackingType: .boolean)
        XCTAssertEqual(linked.goalID, goalID)
        XCTAssertNil(unlinked.goalID)
    }
}
#endif
