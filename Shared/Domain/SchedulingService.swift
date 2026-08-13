import Foundation

enum SchedulingDefaults {
    static let defaultBlockDuration: TimeInterval = 30 * 60
}

struct SchedulingService {
    var defaultDuration: TimeInterval

    init(defaultDuration: TimeInterval = SchedulingDefaults.defaultBlockDuration) {
        self.defaultDuration = max(0, defaultDuration)
    }

    func schedule(
        action: Action,
        at startDate: Date,
        duration: TimeInterval? = nil,
        createdAt: Date = Date()
    ) -> ScheduledBlock {
        let plannedDuration = max(0, duration ?? action.estimatedDuration ?? defaultDuration)
        return ScheduledBlock(
            actionID: action.id,
            goalID: action.goalID,
            title: action.title,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(plannedDuration),
            plannedDuration: plannedDuration,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    func actualDuration(for block: ScheduledBlock, sessions: [FocusSession]) -> TimeInterval {
        sessions.filter { $0.scheduledBlockID == block.id }.reduce(0) { $0 + $1.actualDuration }
    }
}
