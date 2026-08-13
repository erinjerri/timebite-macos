import SwiftUI

private enum HabitGridRange: String, CaseIterable, Identifiable {
    case week
    case month
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct HabitsTrackView: View {
    @ObservedObject var model: TrackViewModel
    @State private var range: HabitGridRange = .week
    @State private var showingNewHabit = false
    private let calendar = Calendar.current

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Picker("Range", selection: $range) {
                        ForEach(HabitGridRange.allCases) { value in Text(value.title).tag(value) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 180)
                    Spacer()
                    Button("New Habit", systemImage: "plus") { showingNewHabit = true }
                        .buttonStyle(.borderedProminent)
                }

                if model.habits.filter({ !$0.isArchived }).isEmpty {
                    TrackingEmptyState(title: "No habits yet", message: "Create a boolean, count, duration, or quantity habit to start tracking consistently.")
                        .frame(minWidth: 900)
                } else {
                    TrackCard(title: rangeTitle) {
                        habitHeader
                        Divider()
                        Text("HABITS")
                            .font(TimeBiteTypography.font(.caption2, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        ForEach(model.habits.filter { !$0.isArchived }) { habit in
                            habitRow(habit)
                        }
                    }
                    .frame(minWidth: max(920, CGFloat(dates.count * 44 + 280)))
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView { title, type, target, unit, recurrence, goalID in
                model.addHabit(title: title, trackingType: type, targetValue: target, unit: unit, recurrence: recurrence, goalID: goalID)
            }
        }
    }

    private var dates: [Date] {
        let component: Calendar.Component = range == .week ? .weekOfYear : .month
        guard let interval = calendar.dateInterval(of: component, for: model.selectedDate) else { return [] }
        let count = range == .week ? 7 : (calendar.range(of: .day, in: .month, for: interval.start)?.count ?? 0)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private var rangeTitle: String {
        range == .week
            ? model.selectedDate.formatted(.dateTime.month(.wide))
            : model.selectedDate.formatted(.dateTime.month(.wide).year())
    }

    private var habitHeader: some View {
        HStack(spacing: 0) {
            Text("Habit").frame(width: 240, alignment: .leading)
            ForEach(dates, id: \.self) { date in
                VStack(spacing: 2) {
                    Text(date, format: .dateTime.day()).font(TimeBiteTypography.font(.caption, weight: .semibold))
                    Text(date, format: .dateTime.weekday(.narrow)).font(TimeBiteTypography.font(.caption2)).foregroundStyle(.secondary)
                }
                .frame(width: 44)
            }
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.title).font(TimeBiteTypography.font(.body, weight: .semibold))
                Text(habitDetail(habit)).font(TimeBiteTypography.font(.caption)).foregroundStyle(.secondary)
            }
            .frame(width: 240, alignment: .leading)
            ForEach(dates, id: \.self) { date in
                Button { model.toggleHabit(habit, on: date) } label: {
                    Image(systemName: model.isHabitComplete(habit, on: date) ? "checkmark.square.fill" : "square")
                        .foregroundStyle(model.isHabitComplete(habit, on: date) ? TimeBitePalette.sky : .secondary)
                        .frame(width: 44, height: 36)
                }
                .buttonStyle(.plain)
                .help("Log \(habit.title) for \(date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }

    private func habitDetail(_ habit: Habit) -> String {
        var parts = [habit.trackingType.rawValue.capitalized, habit.recurrence.rawValue.capitalized]
        if let target = habit.targetValue { parts.append("\(target.formatted()) \(habit.unit ?? "")") }
        if habit.goalID != nil { parts.append("Linked goal") }
        return parts.joined(separator: " · ")
    }
}

private struct NewHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var trackingType: HabitTrackingType = .boolean
    @State private var targetValue = 1.0
    @State private var unit = ""
    @State private var recurrence: HabitRecurrence = .daily
    @State private var goalIDText = ""
    let onSave: (String, HabitTrackingType, Double?, String?, HabitRecurrence, UUID?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Habit").font(TimeBiteTypography.font(.title2, weight: .semibold))
            TextField("Habit title", text: $title)
            Picker("Tracking", selection: $trackingType) {
                ForEach(HabitTrackingType.allCases, id: \.self) { type in Text(type.rawValue.capitalized).tag(type) }
            }
            if trackingType != .boolean {
                HStack {
                    TextField("Target", value: $targetValue, format: .number).frame(width: 120)
                    TextField("Unit", text: $unit)
                }
            }
            Picker("Recurrence", selection: $recurrence) {
                ForEach(HabitRecurrence.allCases, id: \.self) { value in Text(value.rawValue.capitalized).tag(value) }
            }
            TextField("Optional goal ID", text: $goalIDText)
            Text("A goal is optional. Life Area selection will be added when that shared model is connected.")
                .font(TimeBiteTypography.font(.caption))
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), trackingType, trackingType == .boolean ? nil : targetValue, unit.isEmpty ? nil : unit, recurrence, UUID(uuidString: goalIDText))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
