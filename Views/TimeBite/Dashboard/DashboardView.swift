import Charts
import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview
    case progress
    case goals
    case time
    case trends

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct DashboardView: View {
    @State private var section: DashboardSection = .progress
    @StateObject private var viewModel: DashboardViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel())
    }

    @MainActor
    init(viewModel: @autoclosure @escaping () -> DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PrimaryNavigationBar(title: "Dashboard", subtitle: "How am I actually progressing?")
                Spacer()
                Picker("Dashboard view", selection: $section) {
                    ForEach(DashboardSection.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 510)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider()

            switch section {
            case .overview:
                DashboardOverviewView(viewModel: viewModel)
            case .progress:
                DashboardProgressView(viewModel: viewModel)
            case .goals:
                deferred("Goal analysis", symbol: "target", detail: "This view will break down observed progress by Goal without creating a second goal model.")
            case .time:
                deferred("Time allocation", symbol: "clock", detail: "Focus Lane and custom category analysis will use recorded Focus Sessions and tracked activities.")
            case .trends:
                deferred("Long-term trends", symbol: "waveform.path.ecg", detail: "Trend detection will appear when enough historical records exist.")
            }
        }
        .alert("Dashboard could not be loaded", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) { Button("OK") { viewModel.errorMessage = nil } } message: { Text(viewModel.errorMessage ?? "") }
    }

    private func deferred(_ title: String, symbol: String, detail: String) -> some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(detail))
    }
}

private struct DashboardProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Observed Progress")
                            .font(TimeBiteTypography.font(.title2, weight: .semibold))
                        Text("Each line is actual duration divided by planned duration for a recorded category. Values clamp at 100% for display.")
                            .font(TimeBiteTypography.font(.callout))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Time range", selection: Binding(
                        get: { viewModel.range }, set: { viewModel.setRange($0) }
                    )) {
                        ForEach(DashboardRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                }

                if viewModel.metrics.series.isEmpty {
                    emptyProgress
                } else {
                    seriesControls
                    progressChart
                    selectedValues
                    componentMetrics
                }
            }
            .padding(28)
        }
    }

    private var seriesControls: some View {
        HStack(spacing: 10) {
            ForEach(Array(viewModel.series.enumerated()), id: \.element.id) { index, series in
                Button { viewModel.toggleSeries(series.id) } label: {
                    HStack(spacing: 7) {
                        Circle().fill(seriesColor(index)).frame(width: 8, height: 8)
                        Text(series.title)
                        Image(systemName: viewModel.visibleSeriesIDs.contains(series.id) ? "eye.fill" : "eye.slash")
                            .font(.caption2)
                    }
                    .foregroundStyle(viewModel.visibleSeriesIDs.contains(series.id) ? .primary : .secondary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(viewModel.visibleSeriesIDs.contains(series.id) ? "Hide" : "Show") \(series.title)")
            }
        }
    }

    private var progressChart: some View {
        Chart {
            ForEach(viewModel.visiblePoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Progress", point.normalizedValue)
                )
                .foregroundStyle(by: .value("Series", point.seriesTitle))
                .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", point.date), y: .value("Progress", point.normalizedValue))
                    .foregroundStyle(by: .value("Series", point.seriesTitle))
                    .symbolSize(16)
            }
            if let selectedDate = viewModel.selectedDate {
                RuleMark(x: .value("Selected date", selectedDate))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.25, 0.5, 0.75, 1]) { value in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.12))
                AxisValueLabel { if let number = value.as(Double.self) { Text(number, format: .percent.precision(.fractionLength(0))) } }
            }
        }
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 7)) }
        .chartLegend(.hidden)
        .chartXSelection(value: $viewModel.selectedDate)
        .frame(minHeight: 390)
        .padding(18)
        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(TimeBitePalette.border(for: colorScheme)) }
        .accessibilityLabel("Progress by tracked category")
        .accessibilityHint("Drag across the chart to inspect values by date")
    }

    @ViewBuilder
    private var selectedValues: some View {
        if let date = viewModel.selectedDate {
            VStack(alignment: .leading, spacing: 10) {
                Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                if viewModel.selectedPoints.isEmpty {
                    Text("No supported progress values recorded on this date.").foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 24) {
                        ForEach(viewModel.selectedPoints) { point in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.seriesTitle).foregroundStyle(.secondary)
                                Text(point.normalizedValue, format: .percent.precision(.fractionLength(0)))
                                    .font(TimeBiteTypography.font(.title3, weight: .semibold))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var componentMetrics: some View {
        if !viewModel.metrics.components.isEmpty {
            Text("Transparent Components")
                .font(TimeBiteTypography.font(.headline, weight: .semibold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                ForEach(viewModel.metrics.components) { metric in DashboardMetricCard(metric: metric) }
            }
        }
    }

    private var emptyProgress: some View {
        ContentUnavailableView(
            "No comparable progress data",
            systemImage: "chart.xyaxis.line",
            description: Text("Progress lines require tracked activities with both actual and planned durations. TimeBite will not fabricate a score when either value is missing.")
        )
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    private func seriesColor(_ index: Int) -> Color {
        [TimeBitePalette.sky, TimeBitePalette.teal, TimeBitePalette.gold, TimeBitePalette.violet, .pink][index % 5]
    }
}

private struct DashboardOverviewView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Observed signals from the last \(viewModel.range.dayCount) days")
                    .font(TimeBiteTypography.font(.title2, weight: .semibold))
                if !viewModel.metrics.hasData {
                    ContentUnavailableView(
                        "No dashboard data yet",
                        systemImage: "rectangle.grid.2x2",
                        description: Text("Complete Actions, run Focus Sessions, or record habits to populate this measurement workspace.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        if let focused = viewModel.metrics.focusedTime {
                            OverviewCard(title: "Focused Time", value: duration(focused), detail: "Recorded execution")
                        }
                        if let actions = viewModel.metrics.completedActions {
                            OverviewCard(title: "Actions Completed", value: "\(actions)", detail: "From daily tracking records")
                        }
                        ForEach(viewModel.metrics.components) { metric in DashboardMetricCard(metric: metric) }
                    }
                }
            }
            .padding(28)
        }
    }

    private func duration(_ value: TimeInterval) -> String { String(format: "%.1fh", value / 3_600) }
}

private struct DashboardMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let metric: DashboardComponentMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(metric.title).font(TimeBiteTypography.font(.headline, weight: .semibold))
            Text(metric.value, format: .percent.precision(.fractionLength(0)))
                .font(TimeBiteTypography.font(size: 30, weight: .semibold, relativeTo: .title))
            ProgressView(value: metric.value).tint(TimeBitePalette.sky)
            Text(metric.detail).font(TimeBiteTypography.font(.caption)).foregroundStyle(.secondary)
        }
        .padding(17)
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(TimeBitePalette.border(for: colorScheme)) }
    }
}

private struct OverviewCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(TimeBiteTypography.font(.headline, weight: .semibold))
            Text(value).font(TimeBiteTypography.font(size: 30, weight: .semibold, relativeTo: .title))
            Text(detail).font(TimeBiteTypography.font(.caption)).foregroundStyle(.secondary)
        }
        .padding(17)
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(TimeBitePalette.border(for: colorScheme)) }
    }
}

#Preview {
    let tracking = PreviewTrackingRepository.dashboard()
    DashboardView(viewModel: DashboardViewModel(
        planningRepository: InMemoryPlanningRepository(),
        trackingRepository: tracking,
        habitRepository: tracking
    ))
    .frame(width: 1300, height: 800)
}
