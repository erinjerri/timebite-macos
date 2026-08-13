import SwiftUI

struct AnnualTrackView: View {
    @ObservedObject var model: TrackViewModel
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DatePicker("Year", selection: $model.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: 220)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 16)], spacing: 16) {
                    ForEach(months, id: \.self) { month in
                        monthCard(month)
                    }
                }
            }
            .padding(24)
        }
    }

    private var months: [Date] {
        guard let year = calendar.dateInterval(of: .year, for: model.selectedDate)?.start else { return [] }
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: year) }
    }

    private func monthCard(_ month: Date) -> some View {
        let summary = model.monthlySummary(for: month)
        return TrackCard(title: month.formatted(.dateTime.month(.wide))) {
            if let alignment = summary.alignment {
                HStack {
                    ActivityRingView(
                        progress: alignment,
                        accentColor: TimeBitePalette.sky,
                        primaryLabel: alignment.trackingPercent,
                        secondaryLabel: "Alignment",
                        lineWidth: 8
                    )
                    .frame(width: 88, height: 88)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        Text(summary.focusedTime.trackingDuration).font(TimeBiteTypography.font(.title3, weight: .semibold))
                        Text("focused").foregroundStyle(.secondary)
                        if let planned = summary.plannedFocusTime { Text("\(planned.trackingDuration) planned").foregroundStyle(.secondary) }
                    }
                }
                if let consistency = summary.habitConsistency {
                    Label("\(consistency.trackingPercent) habit consistency", systemImage: "checkmark.square").foregroundStyle(.secondary)
                }
                if !summary.mostInvestedAreas.isEmpty {
                    Text("Most invested: \(summary.mostInvestedAreas.joined(separator: ", "))").foregroundStyle(.secondary)
                }
            } else {
                Text("No supported data").foregroundStyle(.secondary).frame(minHeight: 88)
            }
        }
    }
}
