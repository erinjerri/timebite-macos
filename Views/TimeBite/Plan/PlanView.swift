import SwiftUI
import Foundation
import Combine
import UniformTypeIdentifiers
#if canImport(Vision)
import Vision
#endif

enum PlanSection: String, CaseIterable, Identifiable {
    case workspace
    case calendar
    case timeline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace: return "Studio"
        case .calendar: return "Calendar"
        case .timeline: return "Timeline"
        }
    }

    var subtitle: String {
        switch self {
        case .workspace: return "Project intake + frameworks"
        case .calendar: return "Scheduled blocks"
        case .timeline: return "Roadmap"
        }
    }
}

struct PlanView: View {
    @State private var section: PlanSection = .workspace

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                PrimaryNavigationBar(
                    title: "Plan",
                    subtitle: "How will I work on all of this?"
                )
                Spacer(minLength: 16)
                Picker("Plan view", selection: $section) {
                    ForEach(PlanSection.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 420)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Divider()

            switch section {
            case .workspace:
                PlanningWorkbenchView()
            case .calendar:
                TimeBiteCalendarView()
            case .timeline:
                PlanningTimelineView()
            }
        }
    }
}

struct PlanningWorkbenchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: PlanningWorkbenchViewModel
    @State private var isImportingImage = false
    @AppStorage("timebite.plan.framework.gantt.v1") private var showsGantt = true
    @AppStorage("timebite.plan.framework.kanban.v1") private var showsKanban = true
    @AppStorage("timebite.plan.framework.matrix.v1") private var showsMatrix = true

    init(repository: (any PlanningRepository)? = nil) {
        _viewModel = StateObject(wrappedValue: PlanningWorkbenchViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                intakeCard
                frameworkChooser

                if showsGantt {
                    PlanningSurfaceCard(title: "Gantt", systemImage: "chart.bar.xaxis", tint: TimeBitePalette.sky) {
                        PlanningGanttView(items: viewModel.displayedItems)
                    }
                }

                if showsKanban {
                    PlanningSurfaceCard(title: "Kanban", systemImage: "rectangle.3.group", tint: TimeBitePalette.violet) {
                        PlanningKanbanView(items: viewModel.displayedItems)
                    }
                }

                if showsMatrix {
                    PlanningSurfaceCard(title: "Eisenhower Matrix", systemImage: "square.grid.2x2", tint: TimeBitePalette.gold) {
                        PlanningEisenhowerView(items: viewModel.displayedItems)
                    }
                }

                captureCard
            }
            .padding(24)
        }
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.background(for: colorScheme))
        .alert("Planning capture failed", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fileImporter(
            isPresented: $isImportingImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await viewModel.captureImage(from: url) }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .onAppear {
            viewModel.reload()
        }
    }

    private var heroCard: some View {
        PlanningSurfaceCard(title: "Project studio", systemImage: "sparkles", tint: TimeBitePalette.blue) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    PlanningBadge(icon: "tray.full", tint: TimeBitePalette.blue, title: "\(viewModel.displayedItems.count)", subtitle: "projects")
                    PlanningBadge(icon: "calendar", tint: TimeBitePalette.green, title: "\(viewModel.spreadCount)", subtitle: "weeks spread")
                    PlanningBadge(icon: "waveform.path.ecg", tint: TimeBitePalette.violet, title: viewModel.topPrioritySummary, subtitle: "priority mix")
                }

                Text("Paste any number of projects, pull in your existing goals and actions, or scan a handwritten page. The studio turns the list into three thinking modes: Gantt for time, Kanban for flow, and Eisenhower for triage.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
        }
    }

    private var intakeCard: some View {
        PlanningSurfaceCard(title: "Project intake", systemImage: "list.bullet.rectangle", tint: TimeBitePalette.green) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Source", selection: Binding(
                    get: { viewModel.source },
                    set: { viewModel.setSource($0) }
                )) {
                    ForEach(PlanningWorkbenchSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TimeBitePalette.elevatedSurface(for: colorScheme))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
                        }
                        .frame(minHeight: 190)

                    if viewModel.rawText.isEmpty {
                        Text("Paste one project per line.\n\nExamples:\n- Timebite platform rebuild\n- HealthKit sleep sync\n- OCR planner import")
                            .font(TimeBiteTypography.font(.callout))
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                            .padding(16)
                    }

                    TextEditor(text: Binding(
                        get: { viewModel.rawText },
                        set: { viewModel.updateRawText($0) }
                    ))
                    .font(TimeBiteTypography.font(.body))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 190)
                }

                HStack(spacing: 10) {
                    Button {
                        viewModel.loadSamplePaste()
                    } label: {
                        Label("Load sample", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        isImportingImage = true
                    } label: {
                        Label("Scan planner page", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Text("\(viewModel.manualItems.count) parsed manually")
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
            }
        }
    }

    private var frameworkChooser: some View {
        PlanningSurfaceCard(title: "Framework widgets", systemImage: "slider.horizontal.3", tint: TimeBitePalette.sky) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 14)], alignment: .leading, spacing: 14) {
                PlanningWidgetToggle(
                    title: "Gantt",
                    subtitle: "See work spread across time.",
                    systemImage: "chart.bar.xaxis",
                    tint: TimeBitePalette.sky,
                    isOn: $showsGantt
                )
                PlanningWidgetToggle(
                    title: "Kanban",
                    subtitle: "Move work through stages.",
                    systemImage: "rectangle.3.group",
                    tint: TimeBitePalette.violet,
                    isOn: $showsKanban
                )
                PlanningWidgetToggle(
                    title: "Eisenhower",
                    subtitle: "Separate urgent from important.",
                    systemImage: "square.grid.2x2",
                    tint: TimeBitePalette.gold,
                    isOn: $showsMatrix
                )
            }
        }
    }

    private var captureCard: some View {
        PlanningSurfaceCard(title: "OCR capture", systemImage: "doc.viewfinder", tint: TimeBitePalette.teal) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Scan or import a planner page. TimeBite recognizes the handwriting, turns it into JSON, and pre-populates the intake list.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                if let capture = viewModel.lastCapture {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recognized text")
                                .font(TimeBiteTypography.font(.headline, weight: .semibold))
                            Spacer()
                            Button("Use this text") {
                                viewModel.applyCapture()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        ScrollView {
                            Text(capture.recognizedText.isEmpty ? "No text detected yet." : capture.recognizedText)
                                .font(.system(.callout, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(minHeight: 110)
                        .padding(12)
                        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("JSON preview")
                                .font(TimeBiteTypography.font(.headline, weight: .semibold))
                            ScrollView {
                                Text(capture.jsonString)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Text("\(capture.projects.count) projects captured")
                            .font(TimeBiteTypography.font(.caption))
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    }
                } else if viewModel.isCapturing {
                    ProgressView("Reading handwriting...")
                } else {
                    ContentUnavailableView(
                        "No capture yet",
                        systemImage: "text.viewfinder",
                        description: Text("Import an image of a paper planner page to auto-fill the project intake field.")
                    )
                }
            }
        }
    }
}

private struct PlanningSurfaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(TimeBiteTypography.font(.title3, weight: .semibold))
                Spacer()
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: TimeBitePalette.shadow(for: colorScheme), radius: 18, x: 0, y: 8)
    }
}

private struct PlanningWidgetToggle: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    Text(subtitle)
                        .font(TimeBiteTypography.font(.callout))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? tint : TimeBitePalette.secondaryText(for: colorScheme))
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isOn ? tint.opacity(0.10) : TimeBitePalette.elevatedSurface(for: colorScheme))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isOn ? tint.opacity(0.35) : TimeBitePalette.border(for: colorScheme), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PlanningBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                Text(subtitle)
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PlanningGanttView: View {
    @Environment(\.colorScheme) private var colorScheme
    let items: [PlanningWorkbenchItem]
    private let rowHeight: CGFloat = 36
    private let labelWidth: CGFloat = 220
    private let pointsPerDay: CGFloat = 22

    var body: some View {
        let displayItems = PlanningGanttPlanner.makeRows(from: items)
        let range = PlanningGanttPlanner.visibleRange(for: displayItems)
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                ganttHeader(range: range)
                ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(TimeBiteTypography.font(.callout, weight: .semibold))
                                .lineLimit(1)
                            Text(item.subtitle)
                                .font(TimeBiteTypography.font(.caption))
                                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                                .lineLimit(1)
                        }
                        .frame(width: labelWidth, alignment: .leading)

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(TimeBitePalette.border(for: colorScheme))
                                .frame(height: 1)
                                .offset(y: rowHeight / 2)

                            let start = item.startDate
                            let end = item.targetDate
                            let startOffset = max(0, start.timeIntervalSince(range.start) / 86_400.0)
                            let widthDays = max(1, end.timeIntervalSince(start) / 86_400.0)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(item.tint.gradient)
                                .frame(width: CGFloat(widthDays) * pointsPerDay, height: 22)
                                .offset(x: CGFloat(startOffset) * pointsPerDay, y: 7)
                                .overlay(alignment: .leading) {
                                    Text(item.shortLabel)
                                        .font(TimeBiteTypography.font(.caption, weight: .semibold))
                                        .foregroundStyle(Color.black.opacity(0.8))
                                        .lineLimit(1)
                                        .padding(.horizontal, 8)
                                        .frame(width: CGFloat(widthDays) * pointsPerDay, alignment: .leading)
                                }
                        }
                        .frame(width: max(640, CGFloat(range.duration / 86_400.0) * pointsPerDay), height: rowHeight)
                    }
                    .padding(.vertical, 4)
                    .overlay(alignment: .bottom) {
                        Divider().opacity(0.5)
                    }
                }
            }
            .padding(.vertical, 2)
            .frame(minWidth: labelWidth + max(640, CGFloat(range.duration / 86_400.0) * pointsPerDay), alignment: .leading)
        }
        .frame(minHeight: 260)
    }

    private func ganttHeader(range: DateInterval) -> some View {
        HStack(spacing: 0) {
            Text("Project")
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                .frame(width: labelWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                ForEach(PlanningGanttPlanner.gridDates(for: range), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 3) {
                        Rectangle()
                            .fill(TimeBitePalette.border(for: colorScheme))
                            .frame(width: 1)
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(TimeBiteTypography.font(.caption))
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    }
                    .offset(x: PlanningGanttPlanner.xPosition(for: date, in: range, pointsPerDay: pointsPerDay))
                }
            }
            .frame(width: max(640, CGFloat(range.duration / 86_400.0) * pointsPerDay), height: 36, alignment: .leading)
        }
    }
}

private struct PlanningKanbanView: View {
    @Environment(\.colorScheme) private var colorScheme
    let items: [PlanningWorkbenchItem]
    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 14, alignment: .top)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            PlanningKanbanColumn(title: "Backlog", tint: TimeBitePalette.sky, items: items.filter { $0.boardState == .backlog })
            PlanningKanbanColumn(title: "Active", tint: TimeBitePalette.green, items: items.filter { $0.boardState == .active })
            PlanningKanbanColumn(title: "Blocked", tint: TimeBitePalette.gold, items: items.filter { $0.boardState == .blocked })
            PlanningKanbanColumn(title: "Done", tint: TimeBitePalette.violet, items: items.filter { $0.boardState == .done })
        }
    }
}

private struct PlanningKanbanColumn: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let tint: Color
    let items: [PlanningWorkbenchItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                Spacer()
                Text("\(items.count)")
                    .font(TimeBiteTypography.font(.caption, weight: .semibold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint.opacity(0.10), in: Capsule())
            }

            if items.isEmpty {
                Text("Nothing here yet.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(TimeBiteTypography.font(.callout, weight: .semibold))
                                .lineLimit(2)
                            Text(item.shortLabel)
                                .font(TimeBiteTypography.font(.caption))
                                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct PlanningEisenhowerView: View {
    @Environment(\.colorScheme) private var colorScheme
    let items: [PlanningWorkbenchItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PlanningQuadrant(title: "Do now", subtitle: "Urgent + important", tint: TimeBitePalette.green, items: items.filter { $0.isUrgent && $0.isImportant })
                PlanningQuadrant(title: "Schedule", subtitle: "Important, not urgent", tint: TimeBitePalette.sky, items: items.filter { !$0.isUrgent && $0.isImportant })
                PlanningQuadrant(title: "Delegate", subtitle: "Urgent, less important", tint: TimeBitePalette.gold, items: items.filter { $0.isUrgent && !$0.isImportant })
                PlanningQuadrant(title: "Eliminate", subtitle: "Not urgent, not important", tint: TimeBitePalette.violet, items: items.filter { !$0.isUrgent && !$0.isImportant })
            }
        }
    }
}

private struct PlanningQuadrant: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let tint: Color
    let items: [PlanningWorkbenchItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    Text(subtitle)
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
                Spacer()
                Text("\(items.count)")
                    .font(TimeBiteTypography.font(.caption, weight: .semibold))
                    .foregroundStyle(tint)
            }

            if items.isEmpty {
                Text("No items.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    .padding(.vertical, 8)
            } else {
                ForEach(items.prefix(5)) { item in
                    Text(item.title)
                        .font(TimeBiteTypography.font(.callout, weight: .medium))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        }
    }
}

@MainActor
final class PlanningWorkbenchViewModel: ObservableObject {
    @Published private(set) var manualItems: [PlanningWorkbenchItem] = []
    @Published private(set) var repositoryItems: [PlanningWorkbenchItem] = []
    @Published private(set) var lastCapture: PlanningCaptureSummary?
    @Published private(set) var isCapturing = false
    @Published var errorMessage: String?
    @Published var rawText: String
    @Published var source: PlanningWorkbenchSource

    private let repository: any PlanningRepository
    private let calendar: Calendar
    private let defaults: UserDefaults
    private let rawTextKey = "timebite.plan.manualProjects.v1"
    private let sourceKey = "timebite.plan.source.v1"

    init(
        repository: (any PlanningRepository)? = nil,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.repository = repository ?? LocalPlanningRepository()
        self.defaults = defaults
        self.calendar = calendar
        self.source = PlanningWorkbenchSource(rawValue: defaults.string(forKey: sourceKey) ?? PlanningWorkbenchSource.combined.rawValue) ?? .combined
        self.rawText = defaults.string(forKey: rawTextKey) ?? Self.samplePaste
        reload()
    }

    var displayedItems: [PlanningWorkbenchItem] {
        switch source {
        case .manual:
            return manualItems
        case .repository:
            return repositoryItems
        case .combined:
            return repositoryItems + manualItems
        }
    }

    var spreadCount: Int {
        let weeks = Set(displayedItems.map { calendar.component(.weekOfYear, from: $0.startDate) })
        return max(1, weeks.count)
    }

    var topPrioritySummary: String {
        let urgent = displayedItems.filter { $0.priority == .urgent }.count
        let high = displayedItems.filter { $0.priority == .high }.count
        return "\(urgent) urgent · \(high) high"
    }

    func setSource(_ source: PlanningWorkbenchSource) {
        self.source = source
        defaults.set(source.rawValue, forKey: sourceKey)
    }

    func updateRawText(_ text: String) {
        rawText = text
        defaults.set(text, forKey: rawTextKey)
        manualItems = PlanningCaptureParser.parseProjects(from: text, calendar: calendar, startingIndex: repositoryItems.count)
    }

    func loadSamplePaste() {
        updateRawText(Self.samplePaste)
    }

    func applyCapture() {
        guard let capture = lastCapture else { return }
        updateRawText(capture.recognizedText)
    }

    func captureImage(from url: URL) async {
        isCapturing = true
        defer { isCapturing = false }
        do {
            let recognized = try await PlanningCaptureOCR.recognizeText(from: url)
            let parsed = PlanningCaptureParser.parseProjects(from: recognized, calendar: calendar, startingIndex: repositoryItems.count)
            rawText = recognized
            defaults.set(recognized, forKey: rawTextKey)
            manualItems = parsed
            lastCapture = PlanningCaptureSummary(
                recognizedText: recognized,
                projects: parsed.map {
                    PlanningCaptureProject(
                        title: $0.title,
                        notes: $0.notes,
                        priority: $0.priority.rawValue,
                        boardState: $0.boardState.rawValue
                    )
                }
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload() {
        do {
            let projects = try repository.projects()
            let actions = try repository.actions()
            repositoryItems = PlanningWorkbenchMapper.makeRepositoryItems(
                projects: projects,
                actions: actions,
                calendar: calendar
            )
            manualItems = PlanningCaptureParser.parseProjects(from: rawText, calendar: calendar, startingIndex: repositoryItems.count)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static let samplePaste = """
    1. Timebite platform rebuild
    2. HealthKit sleep sync
    3. OCR planner import
    4. New onboarding flow
    5. Analytics dashboard refresh
    6. Marketing site cleanup
    """
}

struct PlanningWorkbenchItem: Identifiable, Hashable {
    enum Kind: String, Codable, Sendable {
        case project
        case action
        case imported
    }

    enum BoardState: String, Codable, Sendable {
        case backlog
        case active
        case blocked
        case done
    }

    enum Priority: String, Codable, Sendable {
        case low
        case medium
        case high
        case urgent
    }

    var id: UUID
    var title: String
    var notes: String
    var kind: Kind
    var boardState: BoardState
    var priority: Priority
    var startDate: Date
    var targetDate: Date
    var sourceLabel: String
    var accentSeed: String

    var subtitle: String {
        [sourceLabel, priority.rawValue.capitalized].joined(separator: " · ")
    }

    var isUrgent: Bool {
        priority == .urgent || targetDate.timeIntervalSinceNow < 14 * 86_400.0 || title.containsKeyword(["urgent", "deadline", "launch", "today", "asap"])
    }

    var isImportant: Bool {
        priority == .high || priority == .urgent || kind == .project || title.containsKeyword(["core", "ship", "client", "platform", "work"])
    }

    var shortLabel: String {
        "\(priority.rawValue.capitalized) · \(boardState.rawValue.capitalized)"
    }

    var tint: Color {
        switch accentSeed.unicodeScalars.reduce(0, { $0 + Int($1.value) }) % 4 {
        case 0: return TimeBitePalette.sky
        case 1: return TimeBitePalette.green
        case 2: return TimeBitePalette.violet
        default: return TimeBitePalette.gold
        }
    }
}

enum PlanningWorkbenchSource: String, CaseIterable, Identifiable {
    case manual
    case repository
    case combined

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "Manual"
        case .repository: return "Existing"
        case .combined: return "Combined"
        }
    }
}

enum PlanningCaptureParser {
    static func parseProjects(from text: String, calendar: Calendar, startingIndex: Int = 0) -> [PlanningWorkbenchItem] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.enumerated().compactMap { index, rawLine in
            guard let parsed = parseLine(rawLine) else { return nil }
            let sourceIndex = startingIndex + index
            let start = calendar.date(byAdding: .day, value: sourceIndex * 7, to: calendar.startOfDay(for: Date())) ?? Date()
            let durationDays = max(5, min(28, 6 + parsed.title.count / 5))
            let target = calendar.date(byAdding: .day, value: durationDays, to: start) ?? start.addingTimeInterval(TimeInterval(durationDays) * 86_400.0)
            return PlanningWorkbenchItem(
                id: UUID(),
                title: parsed.title,
                notes: parsed.notes,
                kind: .imported,
                boardState: parsed.boardState,
                priority: parsed.priority,
                startDate: start,
                targetDate: target,
                sourceLabel: "Imported",
                accentSeed: parsed.title
            )
        }
    }

    private static func parseLine(_ line: String) -> (title: String, notes: String, priority: PlanningWorkbenchItem.Priority, boardState: PlanningWorkbenchItem.BoardState)? {
        var working = line
        working = working.replacingOccurrences(of: #"^\s*(?:[-*•]|\d+[.)])\s*"#, with: "", options: .regularExpression)
        guard !working.isEmpty else { return nil }
        guard !working.hasSuffix(":") else { return nil }

        let parts = working.components(separatedBy: " | ")
        let title = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? working
        let notes = parts.dropFirst().joined(separator: " | ")
        let lowered = title.lowercased()

        let priority: PlanningWorkbenchItem.Priority
        if lowered.contains("!!") || lowered.contains("[urgent]") || lowered.hasPrefix("p1") {
            priority = .urgent
        } else if lowered.contains("!") || lowered.contains("[high]") || lowered.hasPrefix("p2") {
            priority = .high
        } else if lowered.contains("[low]") || lowered.hasPrefix("p4") {
            priority = .low
        } else {
            priority = .medium
        }

        let boardState: PlanningWorkbenchItem.BoardState
        if lowered.containsKeyword(["blocked", "waiting", "stuck"]) {
            boardState = .blocked
        } else if lowered.containsKeyword(["done", "complete", "shipped", "launched"]) {
            boardState = .done
        } else if lowered.containsKeyword(["now", "active", "doing", "working"]) {
            boardState = .active
        } else {
            boardState = .backlog
        }

        let cleanedTitle = title
            .trimmingCharacters(in: CharacterSet(charactersIn: "!#[]0123456789.- "))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else { return nil }

        return (title: cleanedTitle, notes: notes, priority: priority, boardState: boardState)
    }
}

private enum PlanningWorkbenchMapper {
    static func makeRepositoryItems(
        projects: [Project],
        actions: [Action],
        calendar: Calendar
    ) -> [PlanningWorkbenchItem] {
        let projectItems = projects.enumerated().map { index, project in
            makeItem(
                id: project.id,
                title: project.title,
                notes: project.notes,
                kind: .project,
                boardState: boardState(for: project.status),
                priority: .medium,
                startDate: project.startDate,
                targetDate: project.targetDate,
                sourceLabel: "Project",
                accentSeed: project.title,
                index: index,
                calendar: calendar
            )
        }

        let actionItems = actions.enumerated().map { index, action in
            makeItem(
                id: action.id,
                title: action.title,
                notes: action.notes,
                kind: .action,
                boardState: boardState(for: action.status),
                priority: priority(for: action.priority),
                startDate: action.startDate,
                targetDate: action.targetDate,
                sourceLabel: "Action",
                accentSeed: action.title,
                index: projects.count + index,
                calendar: calendar
            )
        }

        return projectItems + actionItems
    }

    private static func makeItem(
        id: UUID,
        title: String,
        notes: String,
        kind: PlanningWorkbenchItem.Kind,
        boardState: PlanningWorkbenchItem.BoardState,
        priority: PlanningWorkbenchItem.Priority,
        startDate: Date?,
        targetDate: Date?,
        sourceLabel: String,
        accentSeed: String,
        index: Int,
        calendar: Calendar
    ) -> PlanningWorkbenchItem {
        let base = calendar.startOfDay(for: Date())
        let generatedStart = calendar.date(byAdding: .day, value: index * 7, to: base) ?? base
        let generatedDuration = max(5, min(28, 7 + title.count / 5))
        let resolvedStart = startDate ?? generatedStart
        let resolvedTarget = targetDate ?? calendar.date(byAdding: .day, value: generatedDuration, to: resolvedStart) ?? resolvedStart.addingTimeInterval(TimeInterval(generatedDuration) * 86_400.0)

        return PlanningWorkbenchItem(
            id: id,
            title: title,
            notes: notes,
            kind: kind,
            boardState: boardState,
            priority: priority,
            startDate: resolvedStart,
            targetDate: max(resolvedTarget, resolvedStart),
            sourceLabel: sourceLabel,
            accentSeed: accentSeed
        )
    }

    private static func boardState(for status: PlanningEntityStatus) -> PlanningWorkbenchItem.BoardState {
        switch status {
        case .active: return .active
        case .completed: return .done
        case .paused: return .blocked
        case .cancelled: return .done
        }
    }

    private static func boardState(for status: ActionStatus) -> PlanningWorkbenchItem.BoardState {
        switch status {
        case .inbox: return .backlog
        case .planned, .inProgress: return .active
        case .completed, .cancelled: return .done
        }
    }

    private static func priority(for priority: ActionPriority?) -> PlanningWorkbenchItem.Priority {
        switch priority {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .none: return .medium
        }
    }
}

private enum PlanningGanttPlanner {
    static func makeRows(from items: [PlanningWorkbenchItem]) -> [PlanningWorkbenchItem] {
        items.sorted {
            if $0.startDate == $1.startDate { return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            return $0.startDate < $1.startDate
        }
    }

    static func visibleRange(for items: [PlanningWorkbenchItem]) -> DateInterval {
        guard let start = items.map(\.startDate).min(),
              let end = items.map(\.targetDate).max() else {
            let today = Calendar.current.startOfDay(for: Date())
            return DateInterval(start: today, end: today.addingTimeInterval(90 * 86_400.0))
        }
        let paddedStart = Calendar.current.date(byAdding: .day, value: -3, to: start) ?? start
        let paddedEnd = Calendar.current.date(byAdding: .day, value: 7, to: end) ?? end
        return DateInterval(start: paddedStart, end: paddedEnd)
    }

    static func gridDates(for range: DateInterval) -> [Date] {
        let days = max(7, Int(range.duration / 86_400.0))
        let strideBy = max(7, days / 8)
        return stride(from: 0, through: days, by: strideBy).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: range.start)
        }
    }

    static func xPosition(for date: Date, in range: DateInterval, pointsPerDay: CGFloat) -> CGFloat {
        CGFloat(date.timeIntervalSince(range.start) / 86_400.0) * pointsPerDay
    }
}

struct PlanningCaptureSummary: Codable, Hashable {
    var recognizedText: String
    var projects: [PlanningCaptureProject]

    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}

struct PlanningCaptureProject: Codable, Hashable {
    var title: String
    var notes: String
    var priority: String
    var boardState: String
}

enum PlanningCaptureOCR {
    static func recognizeText(from url: URL) async throws -> String {
#if canImport(Vision)
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = [Locale.Language(identifier: "en-US")]

        let observations = try await request.perform(on: url)
        return observations
            .map(\.transcript)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
#else
        throw NSError(domain: "PlanningCaptureOCR", code: 1, userInfo: [NSLocalizedDescriptionKey: "OCR capture is only available on macOS with Vision support."])
#endif
    }
}

private extension String {
    func containsKeyword(_ keywords: [String]) -> Bool {
        let lowered = lowercased()
        return keywords.contains { lowered.contains($0) }
    }
}
