import SwiftUI

struct PlanningTimelineView: View {
    @StateObject private var viewModel: TimelineViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: TimelineViewModel())
    }

    @MainActor
    init(viewModel: @autoclosure @escaping () -> TimelineViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if viewModel.visibleRows.isEmpty {
                ContentUnavailableView(
                    "No timeline items",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Add dates to Goals, Milestones, Projects, or Actions to visualize the intended trajectory.")
                )
            } else {
                TimelineCanvas(viewModel: viewModel)
            }
        }
        .alert("Timeline could not be updated", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) { Button("OK") { viewModel.errorMessage = nil } } message: { Text(viewModel.errorMessage ?? "") }
        .sheet(item: $viewModel.selectedNode) { TimelineInspector(node: $0) }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button { viewModel.navigate(-1) } label: { Image(systemName: "chevron.left") }
                .help("Previous period")
            Button("Today") { viewModel.goToToday() }
                .keyboardShortcut("t", modifiers: [.command])
            Button { viewModel.navigate(1) } label: { Image(systemName: "chevron.right") }
                .help("Next period")
            Text(viewModel.rangeTitle)
                .font(TimeBiteTypography.font(.headline, weight: .semibold))
                .frame(minWidth: 150, alignment: .leading)
            Spacer()
            Picker("Timeline scale", selection: $viewModel.scale) {
                ForEach(TimelineScale.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

private struct TimelineCanvas: View {
    @ObservedObject var viewModel: TimelineViewModel
    private let labelWidth: CGFloat = 280
    private let rowHeight: CGFloat = 42

    var body: some View {
        GeometryReader { geometry in
            let timelineWidth = max(640, geometry.size.width - labelWidth)
            ScrollView([.vertical, .horizontal]) {
                VStack(spacing: 0) {
                    header(width: timelineWidth)
                    ZStack(alignment: .topLeading) {
                        grid(width: timelineWidth, rowCount: viewModel.visibleRows.count)
                        VStack(spacing: 0) {
                            ForEach(viewModel.visibleRows) { row in
                                TimelineRowView(
                                    row: row,
                                    interval: viewModel.visibleInterval,
                                    labelWidth: labelWidth,
                                    timelineWidth: timelineWidth,
                                    rowHeight: rowHeight,
                                    isExpanded: viewModel.expanded.contains(row.id),
                                    onToggle: { viewModel.toggle(row.node) },
                                    onSelect: { viewModel.selectedNode = row.node },
                                    onMove: { viewModel.move(row.node, byDays: $0) },
                                    onResizeStart: { viewModel.resizeStart(row.node, byDays: $0) },
                                    onResizeTarget: { viewModel.resizeTarget(row.node, byDays: $0) }
                                )
                            }
                        }
                    }
                }
                .frame(width: labelWidth + timelineWidth)
            }
        }
    }

    private func header(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text("INTENDED TRAJECTORY")
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 18)
                .frame(width: labelWidth, height: 44, alignment: .leading)
            ZStack(alignment: .leading) {
                ForEach(viewModel.gridDates, id: \.self) { date in
                    Text(gridLabel(date))
                        .font(TimeBiteTypography.font(.caption, weight: .medium))
                        .foregroundStyle(.secondary)
                        .offset(x: xPosition(date, width: width) + 6)
                }
            }
            .frame(width: width, height: 44, alignment: .leading)
        }
        .background(.thinMaterial)
    }

    private func grid(width: CGFloat, rowCount: Int) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(viewModel.gridDates, id: \.self) { date in
                Rectangle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 1, height: CGFloat(rowCount) * rowHeight)
                    .offset(x: labelWidth + xPosition(date, width: width))
            }
        }
    }

    private func xPosition(_ date: Date, width: CGFloat) -> CGFloat {
        let total = viewModel.visibleInterval.duration
        return CGFloat(date.timeIntervalSince(viewModel.visibleInterval.start) / total) * width
    }

    private func gridLabel(_ date: Date) -> String {
        viewModel.scale == .month
            ? date.formatted(.dateTime.month(.abbreviated).day())
            : date.formatted(.dateTime.month(.wide))
    }
}

private struct TimelineRowView: View {
    let row: TimelineRow
    let interval: DateInterval
    let labelWidth: CGFloat
    let timelineWidth: CGFloat
    let rowHeight: CGFloat
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void
    let onMove: (Int) -> Void
    let onResizeStart: (Int) -> Void
    let onResizeTarget: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                if row.node.children.isEmpty {
                    Color.clear.frame(width: 16, height: 16)
                } else {
                    Button(action: onToggle) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .help(isExpanded ? "Collapse" : "Expand")
                }
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .frame(width: 16)
                Text(row.node.title)
                    .font(TimeBiteTypography.font(.body, weight: row.depth == 0 ? .semibold : .regular))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.leading, 12 + CGFloat(row.depth) * 18)
            .padding(.trailing, 10)
            .frame(width: labelWidth, height: rowHeight)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)

            ZStack(alignment: .leading) {
                if let start = row.node.startDate, let target = row.node.targetDate,
                   target >= interval.start, start <= interval.end {
                    let clippedStart = max(start, interval.start)
                    let clippedTarget = min(target, interval.end)
                    let x = position(clippedStart)
                    let width = max(12, position(clippedTarget) - x)
                    TimelineBar(
                        title: row.node.title,
                        color: color,
                        width: width,
                        pointsPerDay: timelineWidth / max(1, interval.duration / 86_400),
                        onSelect: onSelect,
                        onMove: onMove,
                        onResizeStart: onResizeStart,
                        onResizeTarget: onResizeTarget
                    )
                    .offset(x: x)
                } else if !row.node.hasTimeline {
                    Text("No dates")
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 8)
                }
            }
            .frame(width: timelineWidth, height: rowHeight, alignment: .leading)
        }
        .overlay(alignment: .bottom) { Divider().opacity(0.45) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.node.kind.rawValue), \(row.node.title)")
    }

    private func position(_ date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(interval.start) / interval.duration) * timelineWidth
    }

    private var color: Color {
        switch row.node.kind {
        case .goal: TimeBitePalette.teal
        case .milestone: TimeBitePalette.sky
        case .project: TimeBitePalette.gold
        case .action: TimeBitePalette.violet
        }
    }

    private var symbol: String {
        switch row.node.kind {
        case .goal: "target"
        case .milestone: "flag.fill"
        case .project: "folder.fill"
        case .action: "checkmark.square"
        }
    }
}

private struct TimelineBar: View {
    let title: String
    let color: Color
    let width: CGFloat
    let pointsPerDay: CGFloat
    let onSelect: () -> Void
    let onMove: (Int) -> Void
    let onResizeStart: (Int) -> Void
    let onResizeTarget: (Int) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.gradient)
            Text(title)
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.78))
                .lineLimit(1)
                .padding(.horizontal, 10)
            HStack {
                resizeHandle(action: onResizeStart)
                Spacer()
                resizeHandle(action: onResizeTarget)
            }
        }
        .frame(width: width, height: 28)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .gesture(DragGesture(minimumDistance: 4).onEnded { onMove(days(for: $0.translation.width)) })
        .help("Drag to move. Drag either edge to resize.")
    }

    private func resizeHandle(action: @escaping (Int) -> Void) -> some View {
        Capsule()
            .fill(Color.black.opacity(0.4))
            .frame(width: 5, height: 18)
            .padding(.horizontal, 3)
            .contentShape(Rectangle().inset(by: -5))
            .highPriorityGesture(DragGesture(minimumDistance: 2).onEnded { action(days(for: $0.translation.width)) })
    }

    private func days(for points: CGFloat) -> Int {
        guard pointsPerDay > 0 else { return 0 }
        return Int((points / pointsPerDay).rounded())
    }
}

private struct TimelineInspector: View {
    @Environment(\.dismiss) private var dismiss
    let node: TimelineNode

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.kind.rawValue.uppercased()).font(TimeBiteTypography.font(.caption, weight: .semibold)).foregroundStyle(.secondary)
                    Text(node.title).font(TimeBiteTypography.font(.title2, weight: .semibold))
                }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            LabeledContent("Start", value: node.startDate?.formatted(date: .long, time: .omitted) ?? "Not set")
            LabeledContent("Target", value: node.targetDate?.formatted(date: .long, time: .omitted) ?? "Not set")
            Text("Timeline edits update this planning entity directly. No visual coordinates are persisted.")
                .font(TimeBiteTypography.font(.callout))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420)
    }
}

#Preview {
    PlanningTimelineView(viewModel: TimelineViewModel(repository: InMemoryPlanningRepository(store: .timelinePreview())))
        .frame(width: 1200, height: 720)
}
