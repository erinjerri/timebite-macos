import Combine
import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var scale: TimelineScale = .quarter
    @Published var anchorDate: Date
    @Published var expanded: Set<TimelineEntityID> = []
    @Published var selectedNode: TimelineNode?
    @Published private(set) var nodes: [TimelineNode] = []
    @Published var errorMessage: String?

    private let repository: any PlanningRepository
    private let calendar: Calendar

    init(
        repository: (any PlanningRepository)? = nil,
        anchorDate: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.repository = repository ?? LocalPlanningRepository()
        self.anchorDate = anchorDate
        self.calendar = calendar
        reload(expandAll: true)
    }

    var visibleInterval: DateInterval {
        switch scale {
        case .month:
            return calendar.dateInterval(of: .month, for: anchorDate)
                ?? DateInterval(start: anchorDate, duration: 31 * 86_400)
        case .quarter:
            let month = calendar.component(.month, from: anchorDate)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: anchorDate)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components) ?? anchorDate
            let end = calendar.date(byAdding: .month, value: 3, to: start) ?? start.addingTimeInterval(92 * 86_400)
            return DateInterval(start: start, end: end)
        }
    }

    var rangeTitle: String {
        switch scale {
        case .month:
            return visibleInterval.start.formatted(.dateTime.month(.wide).year())
        case .quarter:
            let quarter = ((calendar.component(.month, from: visibleInterval.start) - 1) / 3) + 1
            return "Q\(quarter) \(calendar.component(.year, from: visibleInterval.start))"
        }
    }

    var visibleRows: [TimelineRow] {
        flatten(nodes, depth: 0)
    }

    var gridDates: [Date] {
        switch scale {
        case .month:
            let days = calendar.dateComponents([.day], from: visibleInterval.start, to: visibleInterval.end).day ?? 30
            return stride(from: 0, through: days, by: 7).compactMap { calendar.date(byAdding: .day, value: $0, to: visibleInterval.start) }
        case .quarter:
            return (0...3).compactMap { calendar.date(byAdding: .month, value: $0, to: visibleInterval.start) }
        }
    }

    func toggle(_ node: TimelineNode) {
        if expanded.contains(node.id) { expanded.remove(node.id) } else { expanded.insert(node.id) }
    }

    func navigate(_ direction: Int) {
        let component: Calendar.Component = scale == .month ? .month : .month
        let value = scale == .month ? direction : direction * 3
        anchorDate = calendar.date(byAdding: component, value: value, to: anchorDate) ?? anchorDate
    }

    func goToToday() { anchorDate = Date() }

    func move(_ node: TimelineNode, byDays days: Int) {
        guard days != 0 else { return }
        perform { try TimelineService(repository: repository).move(node.id, byDays: days, calendar: calendar) }
    }

    func resizeStart(_ node: TimelineNode, byDays days: Int) {
        guard let start = node.startDate, days != 0,
              let date = calendar.date(byAdding: .day, value: days, to: start) else { return }
        perform { try TimelineService(repository: repository).resizeStart(node.id, to: date) }
    }

    func resizeTarget(_ node: TimelineNode, byDays days: Int) {
        guard let target = node.targetDate, days != 0,
              let date = calendar.date(byAdding: .day, value: days, to: target) else { return }
        perform { try TimelineService(repository: repository).resizeTarget(node.id, to: date) }
    }

    private func flatten(_ nodes: [TimelineNode], depth: Int) -> [TimelineRow] {
        nodes.flatMap { node in
            var result = [TimelineRow(node: node, depth: depth)]
            if expanded.contains(node.id) { result.append(contentsOf: flatten(node.children, depth: depth + 1)) }
            return result
        }
    }

    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
            reload(expandAll: false)
        } catch { errorMessage = error.localizedDescription }
    }

    private func reload(expandAll: Bool) {
        do {
            nodes = try TimelineService(repository: repository).hierarchy()
            if expandAll { expanded = Set(allExpandableIDs(in: nodes)) }
            if let selectedID = selectedNode?.id { selectedNode = find(selectedID, in: nodes) }
        } catch { errorMessage = error.localizedDescription }
    }

    private func allExpandableIDs(in nodes: [TimelineNode]) -> [TimelineEntityID] {
        nodes.flatMap { $0.children.isEmpty ? [] : [$0.id] + allExpandableIDs(in: $0.children) }
    }

    private func find(_ id: TimelineEntityID, in nodes: [TimelineNode]) -> TimelineNode? {
        for node in nodes {
            if node.id == id { return node }
            if let child = find(id, in: node.children) { return child }
        }
        return nil
    }
}

extension PlanningStore {
    static func timelinePreview(relativeTo date: Date = Date(), calendar: Calendar = .current) -> PlanningStore {
        let start = calendar.dateInterval(of: .month, for: date)?.start ?? date
        func day(_ value: Int) -> Date { calendar.date(byAdding: .day, value: value, to: start) ?? start }
        let goal = Goal(title: "Launch TimeBite", startDate: day(1), targetDate: day(75))
        let milestone = Milestone(goalID: goal.id, title: "Mac MVP", startDate: day(2), targetDate: day(42))
        let project = Project(goalID: goal.id, milestoneID: milestone.id, title: "Planning workspace", startDate: day(5), targetDate: day(30))
        return PlanningStore(
            goals: [goal], milestones: [milestone], projects: [project],
            actions: [
                Action(goalID: goal.id, milestoneID: milestone.id, projectID: project.id, title: "Goals", startDate: day(5), targetDate: day(12), status: .planned),
                Action(goalID: goal.id, milestoneID: milestone.id, projectID: project.id, title: "Track", startDate: day(13), targetDate: day(20), status: .planned),
                Action(goalID: goal.id, milestoneID: milestone.id, projectID: project.id, title: "Calendar", startDate: day(21), targetDate: day(30), status: .planned)
            ]
        )
    }
}
