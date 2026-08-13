import Foundation

struct ActivityProgressCalculator {
    struct Output: Sendable, Hashable {
        var normalizedProgress: Double
        var rawCompletionRatio: Double
        var clampedProgress: Double
    }

    init() {}

    func calculate(completed: Int, planned: Int) -> Output {
        let safePlanned = max(planned, 0)
        let safeCompleted = max(completed, 0)

        let rawRatio: Double
        if safePlanned == 0 {
            rawRatio = safeCompleted > 0 ? 1 : 0
        } else {
            rawRatio = Double(safeCompleted) / Double(safePlanned)
        }

        let normalized = rawRatio.isFinite ? rawRatio : 0
        let clamped = min(max(normalized, 0), 1)

        return Output(
            normalizedProgress: clamped,
            rawCompletionRatio: normalized,
            clampedProgress: clamped
        )
    }
}
