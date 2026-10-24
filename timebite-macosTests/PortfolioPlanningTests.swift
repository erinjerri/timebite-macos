#if canImport(XCTest)
import XCTest
@testable import timebite_macos

@MainActor
final class PortfolioPlanningTests: XCTestCase {
    func testDogfoodPortfolioCoversEveryRequestedLaneWithoutChangingExecutionStore() {
        let portfolio = PortfolioSeedData.makePortfolio()
        let lanes = portfolio.items.filter { $0.kind == .lifeArea }

        XCTAssertEqual(lanes.count, 8)
        XCTAssertEqual(portfolio.items.count, 63)
        XCTAssertEqual(portfolio.recurringBlocks.count, 5)
        XCTAssertEqual(portfolio.decisionGates.count, 1)
        XCTAssertEqual(portfolio.dependencies.count, 8)
        XCTAssertTrue(PlanningStore().goals.isEmpty)
    }

    func testCypherActiveOperatingPeriodIsExactlyAprilThroughNovember2027() throws {
        let portfolio = PortfolioSeedData.makePortfolio()
        let operatingPeriod = try XCTUnwrap(portfolio.items.first { $0.title == "Active operating period" })
        let calendar = utcCalendar

        XCTAssertEqual(calendar.component(.month, from: operatingPeriod.startDate), 4)
        XCTAssertEqual(calendar.component(.day, from: operatingPeriod.startDate), 1)
        XCTAssertEqual(calendar.component(.month, from: operatingPeriod.endDate), 11)
        XCTAssertEqual(calendar.component(.day, from: operatingPeriod.endDate), 30)
        XCTAssertEqual(operatingPeriod.flexibility, .fixed)
    }

    func testMedicalPlanningUsesNeutralFlexibleSemantics() throws {
        let portfolio = PortfolioSeedData.makePortfolio()
        let fertility = try XCTUnwrap(portfolio.items.first { $0.title == "Fertility / egg-freezing process" })
        let treatment = try XCTUnwrap(portfolio.items.first { $0.title == "Mother's Alzheimer's treatment" })

        XCTAssertEqual(fertility.kind, .personalConstraint)
        XCTAssertEqual(fertility.flexibility, .flexible)
        XCTAssertNotEqual(fertility.status, .atRisk)
        XCTAssertNotEqual(fertility.status, .blocked)
        XCTAssertEqual(treatment.flexibility, .flexible)
    }

    func testEmploymentExitRemainsAnEditableDecisionGate() throws {
        let gate = try XCTUnwrap(PortfolioSeedData.makePortfolio().decisionGates.first)

        XCTAssertEqual(gate.title, "Leave employment?")
        XCTAssertEqual(gate.status, .planned)
        XCTAssertEqual(gate.conditions.count, 5)
        XCTAssertTrue(gate.notes.contains("not a requirement"))
    }

    func testMonthQuarterAndYearUseOnePortfolioAndExpectedIntervals() {
        let anchor = utcDate(2027, 5, 17)
        let viewModel = PortfolioTimelineViewModel(portfolio: PortfolioSeedData.makePortfolio(), anchorDate: anchor, calendar: utcCalendar)
        let itemIDs = Set(viewModel.portfolio.items.map(\.id))

        viewModel.setScale(.month)
        XCTAssertEqual(dayCount(viewModel.visibleInterval), 31)
        XCTAssertEqual(Set(viewModel.portfolio.items.map(\.id)), itemIDs)

        viewModel.setScale(.quarter)
        XCTAssertEqual(utcCalendar.component(.month, from: viewModel.visibleInterval.start), 4)
        XCTAssertEqual(utcCalendar.component(.month, from: viewModel.visibleInterval.end), 7)
        XCTAssertEqual(Set(viewModel.portfolio.items.map(\.id)), itemIDs)

        viewModel.setScale(.year)
        XCTAssertEqual(utcCalendar.component(.year, from: viewModel.visibleInterval.start), 2027)
        XCTAssertEqual(utcCalendar.component(.year, from: viewModel.visibleInterval.end), 2028)
        XCTAssertEqual(Set(viewModel.portfolio.items.map(\.id)), itemIDs)
    }

    func testDependencyModelPreservesFutureRelationshipTypes() {
        let relationships = Set(PortfolioSeedData.makePortfolio().dependencies.map(\.relationship))

        XCTAssertTrue(relationships.contains(.finishToStart))
        XCTAssertTrue(relationships.contains(.startToStart))
        XCTAssertTrue(DependencyRelationship.allCases.contains(.finishToFinish))
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func utcDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func dayCount(_ interval: DateInterval) -> Int {
        utcCalendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0
    }
}
#endif
