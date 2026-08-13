import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var range: DashboardRange = .thirtyDays
    @Published private(set) var metrics: DashboardMetrics
    @Published var visibleSeriesIDs: Set<String> = []
    @Published var selectedDate: Date?
    @Published var errorMessage: String?

    private let planningRepository: any PlanningRepository
    private let trackingRepository: any TrackingRepository
    private let habitRepository: any HabitRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(
        planningRepository: (any PlanningRepository)? = nil,
        trackingRepository: (any TrackingRepository)? = nil,
        habitRepository: (any HabitRepository)? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        let localTracking = LocalTrackingRepository()
        self.planningRepository = planningRepository ?? LocalPlanningRepository()
        self.trackingRepository = trackingRepository ?? localTracking
        self.habitRepository = habitRepository ?? localTracking
        self.calendar = calendar
        self.now = now
        self.metrics = DashboardMetrics(
            interval: DateInterval(start: now(), duration: 0), series: [], components: [],
            focusedTime: nil, completedActions: nil, plannedFocusTime: nil, actualFocusTime: nil, hasData: false
        )
        reload()
    }

    var series: [(id: String, title: String)] {
        Dictionary(grouping: metrics.series, by: \.seriesID)
            .compactMap { id, points in points.first.map { (id, $0.seriesTitle) } }
            .sorted { $0.title < $1.title }
    }

    var visiblePoints: [DashboardSeriesPoint] {
        metrics.series.filter { visibleSeriesIDs.contains($0.seriesID) }
    }

    var selectedPoints: [DashboardSeriesPoint] {
        guard let selectedDate else { return [] }
        return visiblePoints.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    func setRange(_ range: DashboardRange) {
        self.range = range
        reload()
    }

    func toggleSeries(_ id: String) {
        if visibleSeriesIDs.contains(id) { visibleSeriesIDs.remove(id) } else { visibleSeriesIDs.insert(id) }
    }

    func reload() {
        do {
            metrics = DashboardAggregationService().metrics(
                range: range,
                endingAt: now(),
                records: try trackingRepository.dailyRecords(),
                habits: try habitRepository.habits(),
                habitLogs: try trackingRepository.habitLogs(),
                actions: try planningRepository.actions(),
                scheduledBlocks: try planningRepository.scheduledBlocks(),
                focusSessions: try planningRepository.focusSessions(),
                calendar: calendar
            )
            let available = Set(metrics.series.map(\.seriesID))
            visibleSeriesIDs = visibleSeriesIDs.intersection(available)
            if visibleSeriesIDs.isEmpty { visibleSeriesIDs = available }
        } catch { errorMessage = error.localizedDescription }
    }
}

final class PreviewTrackingRepository: TrackingRepository, HabitRepository {
    let records: [DailyTrackingRecord]
    let habitsValue: [Habit]
    let logs: [HabitLog]

    init(records: [DailyTrackingRecord], habits: [Habit], logs: [HabitLog]) {
        self.records = records
        self.habitsValue = habits
        self.logs = logs
    }

    func dailyRecords() throws -> [DailyTrackingRecord] { records }
    func habits() throws -> [Habit] { habitsValue }
    func habitLogs() throws -> [HabitLog] { logs }
    func save(_ habit: Habit) throws {}
    func save(_ log: HabitLog) throws {}
}

extension PreviewTrackingRepository {
    static func dashboard(relativeTo date: Date = Date(), calendar: Calendar = .current) -> PreviewTrackingRepository {
        let categories = [
            ActivityCategory(id: "career", title: "Career"),
            ActivityCategory(id: "health", title: "Health"),
            ActivityCategory(id: "creative", title: "Creative"),
            ActivityCategory(id: "relationships", title: "Relationships")
        ]
        let records = (0..<30).compactMap { offset -> DailyTrackingRecord? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { return nil }
            let activities = categories.enumerated().map { index, category in
                let planned = Double(35 + index * 15) * 60
                let wave = 0.48 + Double((offset * (index + 2)) % 45) / 100
                return TrackedActivity(date: day, title: category.title, category: category, duration: planned * wave, plannedDuration: planned)
            }
            return DailyTrackingRecord(date: day, plannedActions: 5, completedActions: 2 + offset % 4, goalLinkedActions: 3, completedGoalLinkedActions: 1 + offset % 3, plannedFocusTime: 3 * 3_600, activities: activities, reflectionCompleted: offset % 2 == 0)
        }
        return PreviewTrackingRepository(records: records, habits: [], logs: [])
    }
}
