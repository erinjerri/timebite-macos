import SwiftUI

struct MonthlyTrackView: View {
    @ObservedObject var model: TrackViewModel
    @State private var metric: TrackingMetric = .overall
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    DatePicker("Month", selection: $model.selectedDate, displayedComponents: .date).datePickerStyle(.compact)
                    Spacer()
                    Picker("Metric", selection: $metric) {
                        ForEach(TrackingMetric.allCases) { metric in Text(metric.title).tag(metric) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 430)
                }

                TrackCard(title: model.selectedDate.formatted(.dateTime.month(.wide).year())) {
                    calendarGrid
                    HStack(spacing: 20) {
                        legend("checkmark", "Threshold achieved")
                        legend("circle", "Partial")
                        legend("minus", "No data")
                        Spacer()
                        Text("Threshold: \(Int(TrackingThresholds.achieved * 100))%")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
        }
    }

    private var calendarGrid: some View {
        let dates = monthDates
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { day in
                Text(day).font(TimeBiteTypography.font(.caption, weight: .bold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
            ForEach(0..<leadingBlankCount, id: \.self) { _ in Color.clear.frame(height: 70) }
            ForEach(dates, id: \.self) { date in
                Button { model.openDay(date) } label: {
                    VStack(spacing: 8) {
                        Text(date, format: .dateTime.day())
                        Image(systemName: symbol(for: date))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(color(for: date))
                    }
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var monthDates: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: model.selectedDate),
              let range = calendar.range(of: .day, in: .month, for: interval.start) else { return [] }
        return range.compactMap { day in calendar.date(byAdding: .day, value: day - 1, to: interval.start) }
    }

    private var leadingBlankCount: Int {
        guard let first = monthDates.first else { return 0 }
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }

    private func state(for date: Date) -> CalendarProgressState {
        TrackingThresholds.state(for: model.progress(for: date, metric: metric))
    }

    private func symbol(for date: Date) -> String {
        switch state(for: date) { case .achieved: "checkmark"; case .partial: "circle"; case .noData: "minus" }
    }

    private func color(for date: Date) -> Color {
        switch state(for: date) { case .achieved: TimeBitePalette.sky; case .partial: TimeBitePalette.gold; case .noData: .secondary }
    }

    private func legend(_ symbol: String, _ title: String) -> some View {
        Label(title, systemImage: symbol).font(TimeBiteTypography.font(.caption)).foregroundStyle(.secondary)
    }
}
