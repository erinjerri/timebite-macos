import Foundation

struct DashboardAggregationService {
    private let habitCalculator = HabitCompletionCalculator()

    func metrics(
        range: DashboardRange,
        endingAt endDate: Date,
        records: [DailyTrackingRecord],
        habits: [Habit],
        habitLogs: [HabitLog],
        actions: [Action],
        scheduledBlocks: [ScheduledBlock],
        focusSessions: [FocusSession],
        calendar: Calendar = .current
    ) -> DashboardMetrics {
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        let start = calendar.date(byAdding: .day, value: -(range.dayCount - 1), to: calendar.startOfDay(for: endDate)) ?? endDate
        let interval = DateInterval(start: start, end: end)
        let visibleRecords = records.filter { interval.contains($0.date) }
        let visibleBlocks = scheduledBlocks.filter { interval.contains($0.startDate) }
        let visibleSessions = focusSessions.filter { interval.contains($0.startDate) }
        let completedSessions = visibleSessions.filter { $0.status == .completed }
        let visibleLogs = habitLogs.filter { interval.contains($0.date) }

        let series = categorySeries(records: visibleRecords, calendar: calendar)
        var components: [DashboardComponentMetric] = []

        let linkedActions = actions.filter { $0.goalID != nil }
        if !linkedActions.isEmpty {
            let completed = linkedActions.filter(\.isCompleted).count
            components.append(.init(
                id: "goal-actions", title: "Goal-linked actions",
                value: normalized(Double(completed) / Double(linkedActions.count)),
                detail: "\(completed) of \(linkedActions.count) complete"
            ))
        }

        let activeHabits = habits.filter { !$0.isArchived }
        let habitValues = activeHabits.flatMap { habit in
            visibleLogs.filter { $0.habitID == habit.id }.map { habitCalculator.normalizedProgress(for: habit, value: $0.value) }
        }
        if !habitValues.isEmpty {
            components.append(.init(
                id: "habits", title: "Habit consistency",
                value: habitValues.reduce(0, +) / Double(habitValues.count),
                detail: "Based on \(habitValues.count) recorded check-ins"
            ))
        }

        let planned = visibleBlocks.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.plannedDuration }
        let actual = completedSessions.reduce(0) { $0 + $1.actualDuration }
        if planned > 0 {
            components.append(.init(
                id: "planned-actual", title: "Planned vs actual",
                value: normalized(actual / planned),
                detail: "\(duration(actual)) actual of \(duration(planned)) planned"
            ))
        }

        let completedActions = visibleRecords.isEmpty ? nil : visibleRecords.reduce(0) { $0 + $1.completedActions }
        let recordFocus = visibleRecords.reduce(0) { $0 + $1.actualFocusTime }
        let focusedTime: TimeInterval? = !completedSessions.isEmpty ? actual : (visibleRecords.isEmpty ? nil : recordFocus)
        let hasData = !series.isEmpty || !components.isEmpty || focusedTime != nil || completedActions != nil

        return DashboardMetrics(
            interval: interval,
            series: series,
            components: components,
            focusedTime: focusedTime,
            completedActions: completedActions,
            plannedFocusTime: planned > 0 ? planned : nil,
            actualFocusTime: actual > 0 ? actual : nil,
            hasData: hasData
        )
    }

    private func categorySeries(records: [DailyTrackingRecord], calendar: Calendar) -> [DashboardSeriesPoint] {
        let activities = records.flatMap(\.activities).filter { $0.plannedDuration != nil }
        let grouped = Dictionary(grouping: activities) { activity in
            "\(activity.category.id)|\(calendar.startOfDay(for: activity.date).timeIntervalSinceReferenceDate)"
        }
        return grouped.values.compactMap { values in
            guard let first = values.first else { return nil }
            let planned = values.compactMap(\.plannedDuration).reduce(0, +)
            guard planned > 0 else { return nil }
            return DashboardSeriesPoint(
                seriesID: first.category.id,
                seriesTitle: first.category.title,
                date: calendar.startOfDay(for: first.date),
                normalizedValue: normalized(values.reduce(0) { $0 + $1.duration } / planned)
            )
        }.sorted { $0.date < $1.date }
    }

    private func normalized(_ value: Double) -> Double { min(max(value, 0), 1) }

    private func duration(_ interval: TimeInterval) -> String {
        let hours = interval / 3_600
        return hours >= 1 ? String(format: "%.1fh", hours) : "\(Int(interval / 60))m"
    }
}
