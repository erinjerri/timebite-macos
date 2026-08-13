import SwiftUI

struct DailyTrackView: View {
    @ObservedObject var model: TrackViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DatePicker("Day", selection: $model.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: 220)

                if model.dailySummary.hasData || model.dailySummary.habitCompletion != nil {
                    alignmentCard
                    HStack(alignment: .top, spacing: 18) {
                        activityCard
                        VStack(spacing: 18) {
                            reflectionCard(title: "AM Summary", text: model.dailySummary.reflection.amReflection)
                            reflectionCard(title: "PM Summary", text: model.dailySummary.reflection.pmReflection)
                        }
                        .frame(maxWidth: 420)
                    }
                } else {
                    TrackingEmptyState(title: "No activity recorded", message: "Focus sessions, completed actions, habits, and reflections for this day will appear here.")
                }
            }
            .padding(24)
        }
    }

    private var alignmentCard: some View {
        TrackCard(title: "Daily Alignment") {
            HStack(spacing: 32) {
                ActivityRingView(
                    progress: model.dailySummary.alignment.overall,
                    accentColor: TimeBitePalette.sky,
                    primaryLabel: model.dailySummary.alignment.overall.trackingPercent,
                    secondaryLabel: "Overall",
                    lineWidth: 16
                )
                .frame(width: 150, height: 150)

                HStack(spacing: 28) {
                    alignmentMetric("Focus", model.dailySummary.alignment.focus)
                    alignmentMetric("Actions", model.dailySummary.alignment.actions)
                    alignmentMetric("Goals", model.dailySummary.alignment.goals)
                    alignmentMetric("Reflection", model.dailySummary.alignment.reflection)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(model.dailySummary.focusTime.trackingDuration)
                        .font(TimeBiteTypography.font(.title2, weight: .semibold))
                    Text("of \(model.dailySummary.plannedFocusTime.trackingDuration) planned")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var activityCard: some View {
        TrackCard(title: "Today's Activity") {
            if model.dailySummary.activities.isEmpty {
                Text("No timed activity was captured.").foregroundStyle(.secondary)
            } else {
                ForEach(model.dailySummary.activities) { activity in
                    HStack(spacing: 14) {
                        Text(activity.date, format: .dateTime.hour().minute())
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        RoundedRectangle(cornerRadius: 2).fill(TimeBitePalette.teal).frame(width: 4, height: 36)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(activity.title).font(TimeBiteTypography.font(.body, weight: .semibold))
                            Text(activity.category.title).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(activity.duration.trackingDuration).monospacedDigit()
                    }
                    if activity.id != model.dailySummary.activities.last?.id { Divider() }
                }
            }
        }
    }

    private func reflectionCard(title: String, text: String?) -> some View {
        TrackCard(title: title) {
            Text(text ?? "No reflection recorded.")
                .foregroundStyle(text == nil ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)
        }
    }

    private func alignmentMetric(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value.trackingPercent).font(TimeBiteTypography.font(.title3, weight: .semibold)).monospacedDigit()
            Text(title).foregroundStyle(.secondary)
        }
    }
}
