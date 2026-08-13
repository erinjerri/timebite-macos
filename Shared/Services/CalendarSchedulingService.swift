import Foundation

enum CalendarSchedulingError: Error, Equatable {
    case actionNotFound
    case blockNotFound
}

struct CalendarSchedulingService {
    let repository: any PlanningRepository
    private let schedulingService: SchedulingService

    init(
        repository: any PlanningRepository,
        schedulingService: SchedulingService = SchedulingService()
    ) {
        self.repository = repository
        self.schedulingService = schedulingService
    }

    @discardableResult
    func dropAction(id actionID: UUID, at startDate: Date) throws -> ScheduledBlock {
        guard let action = try repository.actions().first(where: { $0.id == actionID }) else {
            throw CalendarSchedulingError.actionNotFound
        }
        let block = schedulingService.schedule(action: action, at: startDate)
        try repository.save(block)
        return block
    }

    @discardableResult
    func moveBlock(id blockID: UUID, to startDate: Date) throws -> ScheduledBlock {
        guard var block = try repository.scheduledBlocks().first(where: { $0.id == blockID }) else {
            throw CalendarSchedulingError.blockNotFound
        }
        block.move(to: startDate)
        try repository.save(block)
        return block
    }

    @discardableResult
    func resizeBlock(id blockID: UUID, to endDate: Date) throws -> ScheduledBlock {
        guard var block = try repository.scheduledBlocks().first(where: { $0.id == blockID }) else {
            throw CalendarSchedulingError.blockNotFound
        }
        block.resize(to: endDate)
        try repository.save(block)
        return block
    }

    @discardableResult
    func updateBlock(_ block: ScheduledBlock) throws -> ScheduledBlock {
        try repository.save(block)
        return block
    }

    @discardableResult
    func completeBlock(id blockID: UUID) throws -> ScheduledBlock {
        guard var block = try repository.scheduledBlocks().first(where: { $0.id == blockID }) else {
            throw CalendarSchedulingError.blockNotFound
        }
        block.complete()
        try repository.save(block)
        return block
    }

    func deleteBlock(id blockID: UUID) throws {
        try repository.deleteScheduledBlock(id: blockID)
    }
}
