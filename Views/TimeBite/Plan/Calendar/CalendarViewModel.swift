import Combine
import Foundation

enum CalendarMode: String, CaseIterable, Identifiable {
    case day
    case week
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CalendarActionFilter: String, CaseIterable, Identifiable {
    case unscheduled
    case scheduled
    case allIncomplete
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unscheduled: "Unscheduled"
        case .scheduled: "Scheduled"
        case .allIncomplete: "All incomplete"
        }
    }
}

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var mode: CalendarMode = .week
    @Published var anchorDate: Date
    @Published var actionFilter: CalendarActionFilter = .allIncomplete
    @Published private(set) var actions: [Action] = []
    @Published private(set) var projects: [Project] = []
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var blocks: [ScheduledBlock] = []
    @Published private(set) var focusSessions: [FocusSession] = []
    @Published private(set) var externalEvents: [ExternalCalendarEvent] = []
    @Published private(set) var calendarAuthorization: CalendarAuthorizationState = .notDetermined
    @Published var selectedBlock: ScheduledBlock?
    @Published var errorMessage: String?

    private let repository: any PlanningRepository
    private let externalProvider: any ExternalCalendarProviding
    private let calendar: Calendar

    init(
        repository: (any PlanningRepository)? = nil,
        externalProvider: (any ExternalCalendarProviding)? = nil,
        anchorDate: Date = Date(),
        previewStore: PlanningStore? = nil,
        calendar: Calendar = .current
    ) {
        self.repository = previewStore.map(InMemoryPlanningRepository.init(store:)) ?? repository ?? LocalPlanningRepository()
        #if canImport(EventKit)
        self.externalProvider = externalProvider ?? EventKitCalendarProvider()
        #else
        self.externalProvider = externalProvider ?? EmptyExternalCalendarProvider()
        #endif
        self.anchorDate = anchorDate
        self.calendar = calendar
        reload()
    }

    var visibleDates: [Date] {
        switch mode {
        case .day:
            return [calendar.startOfDay(for: anchorDate)]
        case .week:
            guard let start = calendar.dateInterval(of: .weekOfYear, for: anchorDate)?.start else { return [] }
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        }
    }

    var visibleInterval: DateInterval {
        let start = visibleDates.first ?? calendar.startOfDay(for: anchorDate)
        let end = calendar.date(byAdding: .day, value: visibleDates.count, to: start) ?? start.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }

    var filteredActions: [Action] {
        let incomplete = actions.filter { !$0.isCompleted && $0.status != .cancelled }
        switch actionFilter {
        case .unscheduled:
            return incomplete.filter { action in !blocks.contains(where: { $0.actionID == action.id }) }
        case .scheduled:
            return incomplete.filter { action in blocks.contains(where: { $0.actionID == action.id }) }
        case .allIncomplete:
            return incomplete
        }
    }

    var dateRangeTitle: String {
        guard let first = visibleDates.first, let last = visibleDates.last else { return "" }
        if mode == .day { return first.formatted(.dateTime.weekday(.wide).month(.wide).day()) }
        if calendar.isDate(first, equalTo: last, toGranularity: .month) {
            return "\(first.formatted(.dateTime.month(.wide))) \(first.formatted(.dateTime.day()))–\(last.formatted(.dateTime.day().year()))"
        }
        return "\(first.formatted(.dateTime.month(.abbreviated).day())) – \(last.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    func blocks(on date: Date) -> [ScheduledBlock] {
        blocks.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    func externalEvents(on date: Date) -> [ExternalCalendarEvent] {
        externalEvents.filter { calendar.isDate($0.startDate, inSameDayAs: date) && !$0.isAllDay }
    }

    func projectTitle(for action: Action) -> String? {
        action.projectID.flatMap { id in projects.first(where: { $0.id == id })?.title }
    }

    func goalTitle(for action: Action) -> String? {
        action.goalID.flatMap { id in goals.first(where: { $0.id == id })?.title }
    }

    func scheduledCount(for action: Action) -> Int {
        blocks.filter { $0.actionID == action.id }.count
    }

    func actualDuration(for block: ScheduledBlock) -> TimeInterval? {
        let sessions = focusSessions.filter { $0.scheduledBlockID == block.id }
        guard !sessions.isEmpty else { return block.actualDuration }
        return SchedulingService().actualDuration(for: block, sessions: sessions)
    }

    func navigate(_ direction: Int) {
        let component: Calendar.Component = mode == .week ? .weekOfYear : .day
        anchorDate = calendar.date(byAdding: component, value: direction, to: anchorDate) ?? anchorDate
        Task { await loadExternalEvents(requestAccess: false) }
    }

    func goToToday() {
        anchorDate = Date()
        Task { await loadExternalEvents(requestAccess: false) }
    }

    func handleDrop(_ payload: CalendarDragPayload, on day: Date, minuteOfDay: Int) {
        let start = calendar.date(byAdding: .minute, value: minuteOfDay, to: calendar.startOfDay(for: day)) ?? day
        do {
            let service = CalendarSchedulingService(repository: repository)
            switch payload.kind {
            case .action:
                try service.dropAction(id: payload.id, at: start)
            case .scheduledBlock:
                try service.moveBlock(id: payload.id, to: start)
            }
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resize(_ block: ScheduledBlock, by minutes: Int) {
        let snappedMinutes = Int((Double(minutes) / 15).rounded()) * 15
        let minimumDuration: TimeInterval = 15 * 60
        let newDuration = max(minimumDuration, block.plannedDuration + Double(snappedMinutes * 60))
        do {
            try CalendarSchedulingService(repository: repository).resizeBlock(id: block.id, to: block.startDate.addingTimeInterval(newDuration))
            reload()
        } catch { errorMessage = error.localizedDescription }
    }

    func saveBlock(_ block: ScheduledBlock) {
        do {
            try CalendarSchedulingService(repository: repository).updateBlock(block)
            selectedBlock = nil
            reload()
        } catch { errorMessage = error.localizedDescription }
    }

    func complete(_ block: ScheduledBlock) {
        do {
            try CalendarSchedulingService(repository: repository).completeBlock(id: block.id)
            selectedBlock = nil
            reload()
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ block: ScheduledBlock) {
        do {
            try CalendarSchedulingService(repository: repository).deleteBlock(id: block.id)
            selectedBlock = nil
            reload()
        } catch { errorMessage = error.localizedDescription }
    }

    func addAction(title: String, estimatedMinutes: Int?, priority: ActionPriority?) {
        do {
            try repository.save(Action(title: title, estimatedDuration: estimatedMinutes.map { Double($0 * 60) }, priority: priority))
            reload()
        } catch { errorMessage = error.localizedDescription }
    }

    func loadExternalEvents(requestAccess: Bool) async {
        let result = await CalendarExternalEventService().load(from: externalProvider, in: visibleInterval, requestAccess: requestAccess)
        calendarAuthorization = result.authorizationState
        externalEvents = result.events
    }

    private func reload() {
        do {
            actions = try repository.actions()
            projects = try repository.projects()
            goals = try repository.goals()
            blocks = try repository.scheduledBlocks()
            focusSessions = try repository.focusSessions()
        } catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
final class EmptyExternalCalendarProvider: ExternalCalendarProviding {
    var authorizationState: CalendarAuthorizationState { .unavailable }
    func requestAccess() async -> CalendarAuthorizationState { .unavailable }
    func events(in interval: DateInterval) async throws -> [ExternalCalendarEvent] { [] }
}

extension PlanningStore {
    static func calendarPreview(relativeTo date: Date = Date(), calendar: Calendar = .current) -> PlanningStore {
        let week = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let goal = Goal(title: "Ship the macOS foundation")
        let project = Project(goalID: goal.id, title: "Plan workspace")
        let actions = [
            Action(goalID: goal.id, projectID: project.id, title: "Draft calendar architecture", estimatedDuration: 5400, priority: .high, status: .inProgress),
            Action(projectID: project.id, title: "Review EventKit permissions", estimatedDuration: 2700, priority: .medium),
            Action(title: "Capture planning notes", priority: .low)
        ]
        let service = SchedulingService()
        let first = service.schedule(action: actions[0], at: calendar.date(byAdding: .hour, value: 10, to: week) ?? week)
        let secondDay = calendar.date(byAdding: .day, value: 2, to: week) ?? week
        let second = service.schedule(action: actions[1], at: calendar.date(byAdding: .hour, value: 14, to: secondDay) ?? secondDay)
        return PlanningStore(goals: [goal], projects: [project], actions: actions, scheduledBlocks: [first, second])
    }
}
