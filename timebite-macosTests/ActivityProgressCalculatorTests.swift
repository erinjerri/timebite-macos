import XCTest
@testable import timebite_macos

final class ActivityProgressCalculatorTests: XCTestCase {
    func testZeroCompletedOfEightPlannedIsZero() {
        let result = ActivityProgressCalculator().calculate(completed: 0, planned: 8)
        XCTAssertEqual(result.normalizedProgress, 0)
        XCTAssertEqual(result.rawCompletionRatio, 0)
    }

    func testFourCompletedOfEightPlannedIsHalf() {
        let result = ActivityProgressCalculator().calculate(completed: 4, planned: 8)
        XCTAssertEqual(result.normalizedProgress, 0.5)
        XCTAssertEqual(result.rawCompletionRatio, 0.5)
    }

    func testEightCompletedOfEightPlannedIsOne() {
        let result = ActivityProgressCalculator().calculate(completed: 8, planned: 8)
        XCTAssertEqual(result.normalizedProgress, 1)
        XCTAssertEqual(result.rawCompletionRatio, 1)
    }

    func testOverCompletionClampsForDisplayButPreservesRawRatio() {
        let result = ActivityProgressCalculator().calculate(completed: 10, planned: 8)
        XCTAssertEqual(result.normalizedProgress, 1)
        XCTAssertEqual(result.clampedProgress, 1)
        XCTAssertEqual(result.rawCompletionRatio, 1.25)
    }
}
