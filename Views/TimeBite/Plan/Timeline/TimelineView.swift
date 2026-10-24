import SwiftUI

struct PlanningTimelineView: View {
    @StateObject private var viewModel: PortfolioTimelineViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: PortfolioTimelineViewModel())
    }

    @MainActor
    init(viewModel: @autoclosure @escaping () -> PortfolioTimelineViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            PortfolioTimelineToolbar(viewModel: viewModel)
            Divider()
            PortfolioSummaryStrip(viewModel: viewModel)
            Divider()
            HStack(spacing: 0) {
                PortfolioTimelineCanvas(viewModel: viewModel)
                Divider()
                PortfolioInspector(row: viewModel.selectedRow)
                    .frame(width: 292)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("portfolio-timeline")
    }
}

private struct PortfolioTimelineToolbar: View {
    @ObservedObject var viewModel: PortfolioTimelineViewModel

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PORTFOLIO ROADMAP")
                    .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                    .tracking(TimeBiteTypography.eyebrowTracking)
                    .foregroundStyle(.secondary)
                Text(viewModel.rangeTitle)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    .contentTransition(.numericText())
            }
            .frame(minWidth: 150, alignment: .leading)

            Button { viewModel.navigate(-1) } label: { Image(systemName: "chevron.left") }
                .help("Previous \(viewModel.scale.title.lowercased())")
            Button("Today") { viewModel.goToToday() }
                .keyboardShortcut("t", modifiers: [.command])
            Button { viewModel.navigate(1) } label: { Image(systemName: "chevron.right") }
                .help("Next \(viewModel.scale.title.lowercased())")
            Button("Fit") { viewModel.fitPortfolio() }
                .help("Fit September 2026 through December 2029")

            Spacer()

            Picker(
                "Timeline scale",
                selection: Binding(
                    get: { viewModel.scale },
                    set: { viewModel.setScale($0) }
                )
            ) {
                ForEach(PortfolioZoomScale.allCases) { scale in
                    Text(scale.title).tag(scale)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 250)
            .accessibilityIdentifier("portfolio-zoom")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

private struct PortfolioSummaryStrip: View {
    @ObservedObject var viewModel: PortfolioTimelineViewModel

    var body: some View {
        HStack(spacing: 22) {
            Label("8 life + venture lanes", systemImage: "square.3.layers.3d")
            Label("Same plan at every zoom", systemImage: "arrow.left.and.right")
            if let milestone = viewModel.nextMilestone {
                Label {
                    Text("Next: \(milestone.title) · \(milestone.endDate.formatted(date: .abbreviated, time: .omitted))")
                } icon: {
                    Image(systemName: "diamond.fill")
                }
            }
            Spacer()
            Text("Seed portfolio · editable model")
                .foregroundStyle(.tertiary)
        }
        .font(TimeBiteTypography.font(.caption, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .frame(height: 42)
    }
}

private struct PortfolioTimelineCanvas: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: PortfolioTimelineViewModel
    private let labelWidth: CGFloat = 300
    private let rowHeight: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let timelineWidth = width(for: geometry.size.width)
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    header(timelineWidth: timelineWidth)
                    ZStack(alignment: .topLeading) {
                        grid(timelineWidth: timelineWidth)
                        VStack(spacing: 0) {
                            ForEach(viewModel.rows) { row in
                                PortfolioTimelineRowView(
                                    row: row,
                                    interval: viewModel.visibleInterval,
                                    labelWidth: labelWidth,
                                    timelineWidth: timelineWidth,
                                    rowHeight: rowHeight,
                                    isSelected: row.id == viewModel.selectedID,
                                    onSelect: { viewModel.select(row) }
                                )
                            }
                        }
                        todayLine(timelineWidth: timelineWidth)
                    }
                }
                .frame(width: labelWidth + timelineWidth, alignment: .topLeading)
            }
            .background(TimeBitePalette.background(for: colorScheme))
        }
    }

    private func header(timelineWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            HStack {
                Text("PLAN HIERARCHY")
                Spacer()
                Text("\(viewModel.rows.count) visible")
                    .foregroundStyle(.tertiary)
            }
            .font(TimeBiteTypography.font(.caption2, weight: .semibold))
            .tracking(TimeBiteTypography.eyebrowTracking)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .frame(width: labelWidth, height: 48)

            ZStack(alignment: .topLeading) {
                ForEach(viewModel.ticks) { tick in
                    Text(tick.label)
                        .font(TimeBiteTypography.font(.caption, weight: tick.isMajor ? .semibold : .medium))
                        .foregroundStyle(tick.isMajor ? .primary : .secondary)
                        .offset(x: xPosition(tick.date, width: timelineWidth) + 8, y: 15)
                }
            }
            .frame(width: timelineWidth, height: 48, alignment: .leading)
        }
        .background(TimeBitePalette.surface(for: colorScheme))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func grid(timelineWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(TimeBitePalette.surface(for: colorScheme))
                .frame(width: labelWidth, height: CGFloat(viewModel.rows.count) * rowHeight)

            ForEach(viewModel.ticks) { tick in
                Rectangle()
                    .fill(Color.secondary.opacity(tick.isMajor ? 0.20 : 0.10))
                    .frame(width: 1, height: CGFloat(viewModel.rows.count) * rowHeight)
                    .offset(x: labelWidth + xPosition(tick.date, width: timelineWidth))
            }
        }
    }

    @ViewBuilder
    private func todayLine(timelineWidth: CGFloat) -> some View {
        let today = Date()
        if viewModel.visibleInterval.contains(today) {
            VStack(spacing: 2) {
                Text("TODAY")
                    .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                    .foregroundStyle(.red)
                    .fixedSize()
                Rectangle().fill(Color.red.opacity(0.72)).frame(width: 1)
            }
            .frame(height: CGFloat(viewModel.rows.count) * rowHeight + 20)
            .offset(x: labelWidth + xPosition(today, width: timelineWidth) - 1, y: -18)
            .allowsHitTesting(false)
        }
    }

    private func width(for availableWidth: CGFloat) -> CGFloat {
        if viewModel.isFitted { return max(1_460, availableWidth - labelWidth) }
        switch viewModel.scale {
        case .month: return max(900, availableWidth - labelWidth)
        case .quarter: return max(920, availableWidth - labelWidth)
        case .year: return max(1_080, availableWidth - labelWidth)
        }
    }

    private func xPosition(_ date: Date, width: CGFloat) -> CGFloat {
        let duration = max(1, viewModel.visibleInterval.duration)
        return CGFloat(date.timeIntervalSince(viewModel.visibleInterval.start) / duration) * width
    }
}

private struct PortfolioTimelineRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let row: PortfolioTimelineRow
    let interval: DateInterval
    let labelWidth: CGFloat
    let timelineWidth: CGFloat
    let rowHeight: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(symbolColor)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.title)
                        .font(TimeBiteTypography.font(.body, weight: row.depth == 0 ? .semibold : .regular))
                        .lineLimit(1)
                    if row.depth == 0 {
                        Text(row.subtitle)
                            .font(TimeBiteTypography.font(.caption2))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                if row.status == .blocked {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .help("Blocked")
                }
            }
            .padding(.leading, 12 + CGFloat(row.depth) * 17)
            .padding(.trailing, 10)
            .frame(width: labelWidth, height: rowHeight)

            ZStack(alignment: .leading) {
                timelineMark
            }
            .frame(width: timelineWidth, height: rowHeight, alignment: .leading)
        }
        .background(isSelected ? TimeBitePalette.sky.opacity(colorScheme == .dark ? 0.12 : 0.18) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .overlay(alignment: .bottom) { Divider().opacity(0.40) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title), \(row.status.rawValue), \(row.flexibility.rawValue) dates")
    }

    @ViewBuilder
    private var timelineMark: some View {
        if row.endDate >= interval.start && row.startDate < interval.end {
            let clippedStart = max(row.startDate, interval.start)
            let clippedEnd = min(row.endDate, interval.end)
            let x = position(clippedStart)
            let barWidth = max(12, position(clippedEnd) - x)

            if row.isDecisionGate {
                DecisionGateMark().offset(x: x - 9)
            } else if row.kind == .milestone {
                MilestoneMark(isFlexible: row.flexibility == .flexible).offset(x: x - 7)
            } else if row.isRecurring {
                RecurringMark(width: barWidth).offset(x: x)
            } else if row.kind == .personalConstraint {
                PersonalConstraintMark(width: barWidth).offset(x: x)
            } else {
                PortfolioBar(row: row, width: barWidth).offset(x: x)
            }
        }
    }

    private func position(_ date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(interval.start) / max(1, interval.duration)) * timelineWidth
    }

    private var symbol: String {
        if row.isDecisionGate { return "arrow.triangle.branch" }
        if row.isRecurring { return "repeat" }
        switch row.kind {
        case .lifeArea: return "square.3.layers.3d"
        case .program: return "rectangle.stack"
        case .project: return "folder"
        case .phase: return "timeline.selection"
        case .milestone: return "diamond.fill"
        case .action: return "checkmark.square"
        case .personalConstraint: return "heart.text.square"
        }
    }

    private var symbolColor: Color {
        switch row.status {
        case .active: TimeBitePalette.sky
        case .blocked: .orange
        case .atRisk: .red
        case .complete: TimeBitePalette.green
        case .idea, .planned, .paused: .secondary
        }
    }
}

private struct PortfolioBar: View {
    let row: PortfolioTimelineRow
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: row.kind == .lifeArea ? 3 : 6, style: .continuous)
                .fill(fillColor.opacity(row.kind == .lifeArea ? 0.34 : 0.72))
            if row.progress > 0 {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor)
                    .frame(width: max(4, width * row.progress))
            }
            if width > 88 && row.kind != .lifeArea {
                Text(row.title)
                    .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: width, height: row.kind == .lifeArea ? 8 : 24)
        .overlay {
            if row.status == .blocked {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
    }

    private var fillColor: Color {
        switch row.status {
        case .active: TimeBitePalette.sky
        case .blocked: Color.orange.opacity(0.42)
        case .atRisk: Color.red.opacity(0.56)
        case .complete: TimeBitePalette.green
        case .paused: Color.secondary.opacity(0.30)
        case .idea: Color.secondary.opacity(0.22)
        case .planned: TimeBitePalette.teal
        }
    }
}

private struct MilestoneMark: View {
    let isFlexible: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isFlexible ? Color.secondary.opacity(0.36) : TimeBitePalette.gold)
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(45))
            .overlay {
                if isFlexible {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .rotationEffect(.degrees(45))
                }
            }
    }
}

private struct DecisionGateMark: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.clear)
            .frame(width: 18, height: 18)
            .overlay { RoundedRectangle(cornerRadius: 2).stroke(TimeBitePalette.violet, lineWidth: 2) }
            .rotationEffect(.degrees(45))
    }
}

private struct RecurringMark: View {
    let width: CGFloat

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<min(160, max(1, Int(width / 11))), id: \.self) { _ in
                Capsule().fill(TimeBitePalette.violet.opacity(0.72)).frame(width: 6, height: 16)
            }
        }
        .frame(width: width, height: 20, alignment: .leading)
        .clipped()
    }
}

private struct PersonalConstraintMark: View {
    let width: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.secondary.opacity(0.12))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.secondary.opacity(0.42), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
            .frame(width: width, height: 22)
    }
}

private struct PortfolioInspector: View {
    let row: PortfolioTimelineRow?

    var body: some View {
        Group {
            if let row {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(inspectorLabel(for: row))
                                .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                                .tracking(TimeBiteTypography.eyebrowTracking)
                                .foregroundStyle(.secondary)
                            Text(row.title)
                                .font(TimeBiteTypography.font(.title3, weight: .semibold))
                            if !row.subtitle.isEmpty {
                                Text(row.subtitle)
                                    .font(TimeBiteTypography.font(.callout))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()
                        inspectorField("Status", row.status.rawValue.displayTitle)
                        inspectorField("Start", row.startDate.formatted(date: .long, time: .omitted))
                        inspectorField("End", row.endDate.formatted(date: .long, time: .omitted))
                        inspectorField("Flexibility", row.flexibility.rawValue.displayTitle)
                        inspectorField("Priority", row.priority.rawValue.displayTitle)
                        if row.progress > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                inspectorField("Progress", row.progress.formatted(.percent.precision(.fractionLength(0))))
                                ProgressView(value: row.progress)
                            }
                        }
                        if !row.conditions.isEmpty {
                            Divider()
                            Text("CONDITIONS")
                                .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                                .tracking(TimeBiteTypography.eyebrowTracking)
                                .foregroundStyle(.secondary)
                            ForEach(row.conditions, id: \.self) { condition in
                                Label(condition, systemImage: "circle")
                                    .font(TimeBiteTypography.font(.callout))
                            }
                        }
                        if !row.notes.isEmpty {
                            Divider()
                            Text(row.notes)
                                .font(TimeBiteTypography.font(.callout))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(20)
                }
            } else {
                ContentUnavailableView(
                    "Select a plan item",
                    systemImage: "sidebar.right",
                    description: Text("Inspect its dates, status, flexibility, and planning context.")
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.background)
    }

    private func inspectorField(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
            .font(TimeBiteTypography.font(.callout))
    }

    private func inspectorLabel(for row: PortfolioTimelineRow) -> String {
        if row.isDecisionGate { return "DECISION GATE" }
        if row.isRecurring { return "RECURRING BLOCK" }
        return row.kind.rawValue.displayTitle.uppercased()
    }
}

private extension String {
    var displayTitle: String {
        unicodeScalars.reduce(into: "") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar), !result.isEmpty { result.append(" ") }
            result.append(String(scalar))
        }
        .replacingOccurrences(of: "To", with: "-to-")
        .capitalized
    }
}

#Preview {
    PlanningTimelineView(
        viewModel: PortfolioTimelineViewModel(
            scale: .quarter,
            anchorDate: PortfolioSeedData.makePortfolio().startDate
        )
    )
    .frame(width: 1_440, height: 820)
}
