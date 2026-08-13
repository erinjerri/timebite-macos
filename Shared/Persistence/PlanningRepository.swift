import Foundation

protocol PlanningRepository {
    func goals() throws -> [Goal]
    func milestones() throws -> [Milestone]
    func projects() throws -> [Project]
    func actions() throws -> [Action]
    func scheduledBlocks() throws -> [ScheduledBlock]
    func focusSessions() throws -> [FocusSession]

    func save(_ goal: Goal) throws
    func save(_ milestone: Milestone) throws
    func save(_ project: Project) throws
    func save(_ action: Action) throws
    func save(_ block: ScheduledBlock) throws
    func save(_ session: FocusSession) throws
    func deleteScheduledBlock(id: UUID) throws
}

struct PlanningStore: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = currentSchemaVersion
    var goals: [Goal] = []
    var milestones: [Milestone] = []
    var projects: [Project] = []
    var actions: [Action] = []
    var scheduledBlocks: [ScheduledBlock] = []
    var focusSessions: [FocusSession] = []
}

enum PlanningRepositoryError: Error {
    case unsupportedSchemaVersion(Int)
}

final class LocalPlanningRepository: PlanningRepository {
    private static let storeKey = "timebite.planningStore.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func goals() throws -> [Goal] { try load().goals }
    func milestones() throws -> [Milestone] { try load().milestones }
    func projects() throws -> [Project] { try load().projects }
    func actions() throws -> [Action] { try load().actions }
    func scheduledBlocks() throws -> [ScheduledBlock] { try load().scheduledBlocks }
    func focusSessions() throws -> [FocusSession] { try load().focusSessions }

    func save(_ goal: Goal) throws { try update { PlanningStoreMutation.upsert(goal, in: &$0.goals) } }
    func save(_ milestone: Milestone) throws { try update { PlanningStoreMutation.upsert(milestone, in: &$0.milestones) } }
    func save(_ project: Project) throws { try update { PlanningStoreMutation.upsert(project, in: &$0.projects) } }
    func save(_ action: Action) throws { try update { PlanningStoreMutation.upsert(action, in: &$0.actions) } }
    func save(_ block: ScheduledBlock) throws { try update { PlanningStoreMutation.upsert(block, in: &$0.scheduledBlocks) } }
    func save(_ session: FocusSession) throws { try update { PlanningStoreMutation.upsert(session, in: &$0.focusSessions) } }

    func deleteScheduledBlock(id: UUID) throws {
        try update { store in
            store.scheduledBlocks.removeAll { $0.id == id }
        }
    }

    private func load() throws -> PlanningStore {
        guard let data = defaults.data(forKey: Self.storeKey) else { return PlanningStore() }
        let store = try decoder.decode(PlanningStore.self, from: data)
        guard store.schemaVersion == PlanningStore.currentSchemaVersion else {
            throw PlanningRepositoryError.unsupportedSchemaVersion(store.schemaVersion)
        }
        return store
    }

    private func update(_ changes: (inout PlanningStore) -> Void) throws {
        var store = try load()
        changes(&store)
        defaults.set(try encoder.encode(store), forKey: Self.storeKey)
    }

}

final class InMemoryPlanningRepository: PlanningRepository {
    private var store: PlanningStore

    init(store: PlanningStore = PlanningStore()) {
        self.store = store
    }

    func goals() throws -> [Goal] { store.goals }
    func milestones() throws -> [Milestone] { store.milestones }
    func projects() throws -> [Project] { store.projects }
    func actions() throws -> [Action] { store.actions }
    func scheduledBlocks() throws -> [ScheduledBlock] { store.scheduledBlocks }
    func focusSessions() throws -> [FocusSession] { store.focusSessions }

    func save(_ goal: Goal) throws { PlanningStoreMutation.upsert(goal, in: &store.goals) }
    func save(_ milestone: Milestone) throws { PlanningStoreMutation.upsert(milestone, in: &store.milestones) }
    func save(_ project: Project) throws { PlanningStoreMutation.upsert(project, in: &store.projects) }
    func save(_ action: Action) throws { PlanningStoreMutation.upsert(action, in: &store.actions) }
    func save(_ block: ScheduledBlock) throws { PlanningStoreMutation.upsert(block, in: &store.scheduledBlocks) }
    func save(_ session: FocusSession) throws { PlanningStoreMutation.upsert(session, in: &store.focusSessions) }
    func deleteScheduledBlock(id: UUID) throws { store.scheduledBlocks.removeAll { $0.id == id } }

}

private enum PlanningStoreMutation {
    static func upsert<Value: Identifiable>(_ value: Value, in values: inout [Value]) where Value.ID == UUID {
        if let index = values.firstIndex(where: { $0.id == value.id }) {
            values[index] = value
        } else {
            values.append(value)
        }
    }
}
