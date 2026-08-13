import SwiftUI

struct WeeklyTrackView: View {
    @ObservedObject var model: TrackViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DatePicker("Week containing", selection: $model.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: 280)

                TrackCard(title: "Seven-Day Alignment") {
                    HStack(spacing: 20) {
                        ForEach(model.weeklySummary.days) { day in
                            Button { model.openDay(day.date) } label: {
                                VStack(spacing: 9) {
                                    ActivityRingView(
                                        progress: day.alignment.overall,
                                        accentColor: day.hasData ? TimeBitePalette.sky : .secondary,
                                        primaryLabel: day.hasData ? day.alignment.overall.trackingPercent : "—",
                                        secondaryLabel: day.date.formatted(.dateTime.weekday(.abbreviated)),
                                        lineWidth: 7
                                    )
                                    .frame(width: 84, height: 84)
                                    Text(day.date, format: .dateTime.day()).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Open \(day.date.formatted(date: .complete, time: .omitted))")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                if model.weeklySummary.hasData {
                    HStack(spacing: 18) {
                        summaryCard("Focus", model.weeklySummary.totalFocusTime.trackingDuration, "of \(model.weeklySummary.plannedFocusTime.trackingDuration) planned")
                        summaryCard("Actions", "\(model.weeklySummary.completedActions)", "completed")
                        summaryCard("Goal-linked", "\(model.weeklySummary.goalLinkedActions)", "completed actions")
                        summaryCard("Habits", model.weeklySummary.habitCompletion?.trackingPercent ?? "—", "consistency")
                    }
                } else {
                    TrackingEmptyState(title: "No weekly activity", message: "This summary aggregates the seven Daily records; it does not create separate weekly data.")
                }

                TrackCard(title: "Weekly Reflection") {
                    Text("A weekly reflection will appear here once the reflection workflow is connected.").foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
    }

    private func summaryCard(_ title: String, _ value: String, _ detail: String) -> some View {
        TrackCard(title: title) {
            Text(value).font(TimeBiteTypography.font(.title2, weight: .semibold)).monospacedDigit()
            Text(detail).foregroundStyle(.secondary)
        }
    }
}
