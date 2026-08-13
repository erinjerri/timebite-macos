import Foundation

struct HabitCompletionCalculator {
    func normalizedProgress(for habit: Habit, value: Double) -> Double {
        let safeValue = max(0, value)
        switch habit.trackingType {
        case .boolean:
            return safeValue > 0 ? 1 : 0
        case .count, .duration, .quantity:
            guard let target = habit.targetValue, target > 0 else { return 0 }
            return min(safeValue / target, 1)
        }
    }

    func isCompleted(_ log: HabitLog, for habit: Habit) -> Bool {
        log.completed || normalizedProgress(for: habit, value: log.value) >= 1
    }
}
