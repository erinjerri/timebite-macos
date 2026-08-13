import Foundation

struct TrackingAggregationService {
    private let progressCalculator = ActivityProgressCalculator()
    private let habitCalculator = HabitCompletionCalculator()

    func daily(
        record: DailyTrackingRecord?,
        habits: [Habit] = [],
        habitLogs: [HabitLog] = [],
        date: Date,
        calendar: Calendar = .current
    ) -> DailyTrackingSummary {
        guard let record else {
            return DailyTrackingSummary(
                date: calendar.startOfDay(for: date),
                alignment: .init(overall: 0, focus: 0, actions: 0, goals: 0, reflection: 0),
                focusTime: 0,
                plannedFocusTime: 0,
                completedActions: 0,
                goalLinkedActions: 0,
                habitCompletion: nil,
                activities: [],
                reflection: .init(),
                hasData: false
            )
        }

        let focus = ratio(actual: record.actualFocusTime, planned: record.plannedFocusTime)
        let actions = progressCalculator.calculate(completed: record.completedActions, planned: record.plannedActions).clampedProgress
        let goals = progressCalculator.calculate(completed: record.completedGoalLinkedActions, planned: record.goalLinkedActions).clampedProgress
        let reflection = record.reflectionCompleted ? 1.0 : 0.0
        let components = [focus, actions, goals, reflection]
        let habitProgress = habitCompletion(habits: habits, logs: habitLogs, date: date, calendar: calendar)
        let overall = components.reduce(0, +) / Double(components.count)

        return DailyTrackingSummary(
            date: calendar.startOfDay(for: record.date),
            alignment: .init(overall: overall, focus: focus, actions: actions, goals: goals, reflection: reflection),
            focusTime: record.actualFocusTime,
            plannedFocusTime: record.plannedFocusTime,
            completedActions: record.completedActions,
            goalLinkedActions: record.completedGoalLinkedActions,
            habitCompletion: habitProgress,
            activities: record.activities.sorted { $0.date < $1.date },
            reflection: record.reflection,
            hasData: true
        )
    }

    func weekly(
        records: [DailyTrackingRecord],
        habits: [Habit] = [],
        habitLogs: [HabitLog] = [],
        containing date: Date,
        calendar: Calendar = .current
    ) -> WeeklyTrackingSummary {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return .init(days: [], totalFocusTime: 0, completedActions: 0, goalLinkedActions: 0, habitCompletion: nil, plannedFocusTime: 0, hasData: false)
        }
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }.map { day in
            let record = records.first { calendar.isDate($0.date, inSameDayAs: day) }
            return daily(record: record, habits: habits, habitLogs: habitLogs, date: day, calendar: calendar)
        }
        let populated = days.filter(\.hasData)
        let habitValues = days.compactMap(\.habitCompletion)
        return WeeklyTrackingSummary(
            days: days,
            totalFocusTime: populated.reduce(0) { $0 + $1.focusTime },
            completedActions: populated.reduce(0) { $0 + $1.completedActions },
            goalLinkedActions: populated.reduce(0) { $0 + $1.goalLinkedActions },
            habitCompletion: habitValues.isEmpty ? nil : habitValues.reduce(0, +) / Double(habitValues.count),
            plannedFocusTime: populated.reduce(0) { $0 + $1.plannedFocusTime },
            hasData: !populated.isEmpty || !habitValues.isEmpty
        )
    }

    func monthly(
        records: [DailyTrackingRecord],
        habits: [Habit] = [],
        habitLogs: [HabitLog] = [],
        containing date: Date,
        calendar: Calendar = .current
    ) -> MonthlyTrackingSummary {
        let month = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let summaries = records
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .map { daily(record: $0, habits: habits, habitLogs: habitLogs, date: $0.date, calendar: calendar) }
        let alignment = summaries.isEmpty ? nil : summaries.reduce(0) { $0 + $1.alignment.overall } / Double(summaries.count)
        let habitValues = summaries.compactMap(\.habitCompletion)
        return MonthlyTrackingSummary(
            month: month,
            alignment: alignment,
            focusedTime: summaries.reduce(0) { $0 + $1.focusTime },
            completedGoals: nil,
            completedMilestones: nil,
            habitConsistency: habitValues.isEmpty ? nil : habitValues.reduce(0, +) / Double(habitValues.count),
            plannedFocusTime: summaries.isEmpty ? nil : summaries.reduce(0) { $0 + $1.plannedFocusTime },
            mostInvestedAreas: investedAreas(from: records)
        )
    }

    func metricProgress(_ metric: TrackingMetric, summary: DailyTrackingSummary) -> Double? {
        guard summary.hasData || metric == .habit else { return nil }
        switch metric {
        case .overall: return summary.hasData ? summary.alignment.overall : nil
        case .goal: return summary.hasData ? summary.alignment.goals : nil
        case .habit: return summary.habitCompletion
        case .focus: return summary.hasData ? summary.alignment.focus : nil
        case .actions: return summary.hasData ? summary.alignment.actions : nil
        }
    }

    private func ratio(actual: TimeInterval, planned: TimeInterval) -> Double {
        guard planned > 0 else { return actual > 0 ? 1 : 0 }
        return min(max(actual / planned, 0), 1)
    }

    private func habitCompletion(habits: [Habit], logs: [HabitLog], date: Date, calendar: Calendar) -> Double? {
        let activeHabits = habits.filter { !$0.isArchived }
        guard !activeHabits.isEmpty else { return nil }
        let progress = activeHabits.map { habit -> Double in
            let value = logs.filter { $0.habitID == habit.id && calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.value }
            return habitCalculator.normalizedProgress(for: habit, value: value)
        }
        return progress.reduce(0, +) / Double(progress.count)
    }

    private func investedAreas(from records: [DailyTrackingRecord]) -> [String] {
        let grouped = Dictionary(grouping: records.flatMap(\.activities), by: { $0.category.title })
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.duration }) }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map(\.0)
    }
}

typealias DailySummaryService = TrackingAggregationService
