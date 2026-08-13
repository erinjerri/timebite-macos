import Foundation

struct ActivityRingProgress: Codable, Hashable, Sendable {
    var normalizedProgress: Double
    var rawCompletionCount: Int
    var plannedCount: Int

    init(normalizedProgress: Double, rawCompletionCount: Int, plannedCount: Int) {
        self.normalizedProgress = normalizedProgress
        self.rawCompletionCount = rawCompletionCount
        self.plannedCount = plannedCount
    }
}
