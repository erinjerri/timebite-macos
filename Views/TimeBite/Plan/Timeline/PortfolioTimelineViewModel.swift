import Combine
import Foundation

enum PortfolioTimelineEntityID: Hashable, Sendable {
    case item(UUID)
    case recurring(UUID)
    case decisionGate(UUID)
}

struct PortfolioTimelineRow: Identifiable, Hashable, Sendable {
    var id: PortfolioTimelineEntityID
    var title: String
    var subtitle: String
    var startDate: Date
    var endDate: Date
    var parentID: UUID?
    var depth: Int
    var kind: PortfolioItemKind
    var status: PortfolioItemStatus
    var priority: PortfolioPriority
    var progress: Double
    var flexibility: PortfolioFlexibility
    var capacity: PortfolioCapacity
    var notes: String
    var conditions: [String]
    var isRecurring: Bool
    var isDecisionGate: Bool
}

struct PortfolioTimelineTick: Identifiable, Hashable, Sendable {
    var id: Date { date }
    var date: Date
    var label: String
    var isMajor: Bool
}

@MainActor
final class PortfolioTimelineViewModel: ObservableObject {
    @Published private(set) var scale: PortfolioZoomScale
    @Published private(set) var anchorDate: Date
    @Published private(set) var isFitted = false
    @Published var selectedID: PortfolioTimelineEntityID?

    let portfolio: Portfolio
    private let calendar: Calendar

    init(
        portfolio: Portfolio? = nil,
        scale: PortfolioZoomScale = .quarter,
        anchorDate: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.portfolio = portfolio ?? PortfolioSeedData.makePortfolio()
        self.scale = scale
        self.anchorDate = anchorDate
        self.calendar = calendar
    }

    var visibleInterval: DateInterval {
        if isFitted {
            let end = calendar.date(byAdding: .day, value: 1, to: portfolio.endDate) ?? portfolio.endDate
            return DateInterval(start: portfolio.startDate, end: end)
        }

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
        case .year:
            return calendar.dateInterval(of: .year, for: anchorDate)
                ?? DateInterval(start: anchorDate, duration: 365 * 86_400)
        }
    }

    var rangeTitle: String {
        if isFitted {
            return "\(calendar.component(.year, from: portfolio.startDate))–\(calendar.component(.year, from: portfolio.endDate))"
        }
        switch scale {
        case .month:
            return visibleInterval.start.formatted(.dateTime.month(.wide).year())
        case .quarter:
            let quarter = ((calendar.component(.month, from: visibleInterval.start) - 1) / 3) + 1
            return "Q\(quarter) \(calendar.component(.year, from: visibleInterval.start))"
        case .year:
            return String(calendar.component(.year, from: visibleInterval.start))
        }
    }

    var rows: [PortfolioTimelineRow] {
        let visibleItemIDs = Set(portfolio.items.filter(intersects).map(\.id))
        let relevantIDs = visibleItemIDs.union(ancestorIDs(for: visibleItemIDs))
        let children = Dictionary(grouping: portfolio.items.filter { $0.parentID != nil }) { $0.parentID! }
        let recurringByParent = Dictionary(grouping: portfolio.recurringBlocks.filter(intersects)) { $0.parentID }
        let gatesByParent = Dictionary(grouping: portfolio.decisionGates.filter(intersects)) { $0.parentID }

        func visit(_ item: PortfolioItem, depth: Int) -> [PortfolioTimelineRow] {
            guard relevantIDs.contains(item.id) else { return [] }
            var result = [row(for: item, depth: depth)]
            for child in children[item.id, default: []] {
                result.append(contentsOf: visit(child, depth: depth + 1))
            }
            result.append(contentsOf: recurringByParent[item.id, default: []].map { row(for: $0, depth: depth + 1) })
            result.append(contentsOf: gatesByParent[item.id, default: []].map { row(for: $0, depth: depth + 1) })
            return result
        }

        return portfolio.items.filter { $0.parentID == nil }.flatMap { visit($0, depth: 0) }
    }

    var ticks: [PortfolioTimelineTick] {
        if isFitted {
            return yearTicks()
        }
        switch scale {
        case .month: return weekTicks()
        case .quarter: return monthTicks()
        case .year: return monthTicks()
        }
    }

    var selectedRow: PortfolioTimelineRow? {
        guard let selectedID else { return nil }
        return rows.first { $0.id == selectedID }
    }

    var activeNowCount: Int {
        portfolio.items.filter { $0.status == .active && intersects($0) && $0.kind != .lifeArea }.count
    }

    var majorWorkstreamCount: Int {
        portfolio.items.filter { intersects($0) && $0.capacity == .high && $0.kind != .lifeArea }.count
    }

    var nextMilestone: PortfolioItem? {
        portfolio.items
            .filter { $0.isMilestone && $0.endDate >= visibleInterval.start }
            .sorted { $0.endDate < $1.endDate }
            .first
    }

    func setScale(_ newScale: PortfolioZoomScale) {
        scale = newScale
        isFitted = false
    }

    func navigate(_ direction: Int) {
        isFitted = false
        let months: Int
        switch scale {
        case .month: months = direction
        case .quarter: months = direction * 3
        case .year: months = direction * 12
        }
        anchorDate = calendar.date(byAdding: .month, value: months, to: anchorDate) ?? anchorDate
    }

    func goToToday() {
        anchorDate = Date()
        isFitted = false
    }

    func fitPortfolio() {
        isFitted = true
    }

    func select(_ row: PortfolioTimelineRow) {
        selectedID = row.id
    }

    private func row(for item: PortfolioItem, depth: Int) -> PortfolioTimelineRow {
        PortfolioTimelineRow(
            id: .item(item.id),
            title: item.title,
            subtitle: item.subtitle,
            startDate: item.startDate,
            endDate: item.endDate,
            parentID: item.parentID,
            depth: depth,
            kind: item.kind,
            status: item.status,
            priority: item.priority,
            progress: item.progress,
            flexibility: item.flexibility,
            capacity: item.capacity,
            notes: item.notes,
            conditions: [],
            isRecurring: false,
            isDecisionGate: false
        )
    }

    private func row(for block: RecurringBlock, depth: Int) -> PortfolioTimelineRow {
        PortfolioTimelineRow(
            id: .recurring(block.id),
            title: block.title,
            subtitle: block.subtitle,
            startDate: block.startDate,
            endDate: block.endDate,
            parentID: block.parentID,
            depth: depth,
            kind: .phase,
            status: .active,
            priority: .medium,
            progress: 0,
            flexibility: block.flexibility,
            capacity: .low,
            notes: block.notes,
            conditions: [],
            isRecurring: true,
            isDecisionGate: false
        )
    }

    private func row(for gate: DecisionGate, depth: Int) -> PortfolioTimelineRow {
        PortfolioTimelineRow(
            id: .decisionGate(gate.id),
            title: gate.title,
            subtitle: "Decision gate",
            startDate: gate.date,
            endDate: gate.date,
            parentID: gate.parentID,
            depth: depth,
            kind: .milestone,
            status: gate.status,
            priority: .high,
            progress: 0,
            flexibility: .target,
            capacity: .low,
            notes: gate.notes,
            conditions: gate.conditions,
            isRecurring: false,
            isDecisionGate: true
        )
    }

    private func intersects(_ item: PortfolioItem) -> Bool {
        item.endDate >= visibleInterval.start && item.startDate < visibleInterval.end
    }

    private func intersects(_ block: RecurringBlock) -> Bool {
        block.endDate >= visibleInterval.start && block.startDate < visibleInterval.end
    }

    private func intersects(_ gate: DecisionGate) -> Bool {
        gate.date >= visibleInterval.start && gate.date < visibleInterval.end
    }

    private func ancestorIDs(for ids: Set<UUID>) -> Set<UUID> {
        let byID = Dictionary(uniqueKeysWithValues: portfolio.items.map { ($0.id, $0) })
        var result = Set<UUID>()
        for id in ids {
            var parentID = byID[id]?.parentID
            while let current = parentID {
                result.insert(current)
                parentID = byID[current]?.parentID
            }
        }
        return result
    }

    private func weekTicks() -> [PortfolioTimelineTick] {
        var dates = [visibleInterval.start]
        var cursor = calendar.date(byAdding: .day, value: 7, to: visibleInterval.start) ?? visibleInterval.end
        while cursor < visibleInterval.end {
            dates.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 7, to: cursor) ?? visibleInterval.end
        }
        return dates.map {
            PortfolioTimelineTick(date: $0, label: $0.formatted(.dateTime.month(.abbreviated).day()), isMajor: true)
        }
    }

    private func monthTicks() -> [PortfolioTimelineTick] {
        var dates = [visibleInterval.start]
        var cursor = calendar.date(byAdding: .month, value: 1, to: visibleInterval.start) ?? visibleInterval.end
        while cursor < visibleInterval.end {
            dates.append(cursor)
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor) ?? visibleInterval.end
        }
        return dates.map {
            let label = scale == .year
                ? $0.formatted(.dateTime.month(.abbreviated))
                : $0.formatted(.dateTime.month(.wide))
            return PortfolioTimelineTick(date: $0, label: label, isMajor: calendar.component(.month, from: $0) == 1)
        }
    }

    private func yearTicks() -> [PortfolioTimelineTick] {
        var ticks: [PortfolioTimelineTick] = []
        var cursor = visibleInterval.start
        while cursor < visibleInterval.end {
            ticks.append(PortfolioTimelineTick(date: cursor, label: String(calendar.component(.year, from: cursor)), isMajor: true))
            cursor = calendar.date(byAdding: .year, value: 1, to: cursor) ?? visibleInterval.end
        }
        return ticks
    }
}
