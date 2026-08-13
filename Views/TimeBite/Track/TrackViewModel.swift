import Combine
import Foundation

@MainActor
final class TrackViewModel: ObservableObject {
    @Published var selectedPeriod: TrackPeriod = .daily
    @Published var selectedDate: Date
    @Published private(set) var records: [DailyTrackingRecord] = []
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var habitLogs: [HabitLog] = []
    @Published private(set) var errorMessage: String?

    private let repository: LocalTrackingRepository?
    private let aggregation = TrackingAggregationService()
    private let calendar: Calendar

    init(
        repository: LocalTrackingRepository? = nil,
        selectedDate: Date = Date(),
        previewData: TrackPreviewData? = nil,
        calendar: Calendar = .current
    ) {
        self.repository = previewData == nil ? (repository ?? LocalTrackingRepository()) : nil
        self.selectedDate = selectedDate
        self.calendar = calendar
        if let previewData {
            records = previewData.records
            habits = previewData.habits
            habitLogs = previewData.logs
        } else {
            reload()
        }
    }

    var dailySummary: DailyTrackingSummary {
        let record = records.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        return aggregation.daily(record: record, habits: habits, habitLogs: habitLogs, date: selectedDate, calendar: calendar)
    }

    var weeklySummary: WeeklyTrackingSummary {
        aggregation.weekly(records: records, habits: habits, habitLogs: habitLogs, containing: selectedDate, calendar: calendar)
    }

    func monthlySummary(for date: Date) -> MonthlyTrackingSummary {
        aggregation.monthly(records: records, habits: habits, habitLogs: habitLogs, containing: date, calendar: calendar)
    }

    func dailySummary(for date: Date) -> DailyTrackingSummary {
        let record = records.first { calendar.isDate($0.date, inSameDayAs: date) }
        return aggregation.daily(record: record, habits: habits, habitLogs: habitLogs, date: date, calendar: calendar)
    }

    func progress(for date: Date, metric: TrackingMetric) -> Double? {
        aggregation.metricProgress(metric, summary: dailySummary(for: date))
    }

    func openDay(_ date: Date) {
        selectedDate = date
        selectedPeriod = .daily
    }

    func addHabit(
        title: String,
        trackingType: HabitTrackingType,
        targetValue: Double?,
        unit: String?,
        recurrence: HabitRecurrence,
        goalID: UUID?
    ) {
        let habit = Habit(
            title: title,
            goalID: goalID,
            trackingType: trackingType,
            targetValue: trackingType == .boolean ? nil : targetValue,
            unit: unit,
            recurrence: recurrence
        )
        do {
            try repository?.save(habit)
            habits.append(habit)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleHabit(_ habit: Habit, on date: Date) {
        let existing = habitLogs.first { $0.habitID == habit.id && calendar.isDate($0.date, inSameDayAs: date) }
        let target = habit.trackingType == .boolean ? 1 : max(habit.targetValue ?? 1, 1)
        let completed = !(existing?.completed ?? false)
        let log = HabitLog(
            id: existing?.id ?? UUID(),
            habitID: habit.id,
            date: calendar.startOfDay(for: date),
            value: completed ? target : 0,
            completed: completed,
            source: .manual,
            createdAt: existing?.createdAt ?? Date()
        )
        do {
            try repository?.save(log)
            if let index = habitLogs.firstIndex(where: { $0.id == log.id }) { habitLogs[index] = log } else { habitLogs.append(log) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isHabitComplete(_ habit: Habit, on date: Date) -> Bool {
        guard let log = habitLogs.first(where: { $0.habitID == habit.id && calendar.isDate($0.date, inSameDayAs: date) }) else { return false }
        return HabitCompletionCalculator().isCompleted(log, for: habit)
    }

    private func reload() {
        do {
            records = try repository?.dailyRecords() ?? []
            habits = try repository?.habits() ?? []
            habitLogs = try repository?.habitLogs() ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TrackPreviewData {
    var records: [DailyTrackingRecord]
    var habits: [Habit]
    var logs: [HabitLog]

    static func sample(relativeTo date: Date = Date(), calendar: Calendar = .current) -> TrackPreviewData {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let goalID = UUID()
        let category = ActivityCategory(id: "deep-work", title: "Deep Work")
        let records = (0..<7).compactMap { offset -> DailyTrackingRecord? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start), offset < 5 else { return nil }
            let activity = TrackedActivity(date: day.addingTimeInterval(9 * 3600), title: "Build Track workspace", category: category, duration: TimeInterval(2400 + offset * 600), plannedDuration: 3600, goalID: goalID)
            return DailyTrackingRecord(
                date: day,
                plannedActions: 5,
                completedActions: 2 + offset,
                goalLinkedActions: 2,
                completedGoalLinkedActions: min(offset + 1, 2),
                plannedFocusTime: 5400,
                activities: [activity],
                reflection: .init(amReflection: "Protect the first focus block.", pmReflection: offset < 3 ? "The main work moved forward." : nil),
                reflectionCompleted: offset < 3
            )
        }
        let habit = Habit(title: "Morning pages", goalID: goalID, trackingType: .count, targetValue: 3, unit: "pages")
        let logs = (0..<4).compactMap { offset -> HabitLog? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return HabitLog(habitID: habit.id, date: day, value: offset == 2 ? 1 : 3, completed: offset != 2)
        }
        return TrackPreviewData(records: records, habits: [habit], logs: logs)
    }
}
