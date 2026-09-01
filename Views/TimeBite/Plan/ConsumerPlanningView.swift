import SwiftUI

private enum ConsumerPlanningScreen: String, CaseIterable, Identifiable {
    case empty
    case create
    case edit
    case move

    var id: String { rawValue }

    var title: String {
        switch self {
        case .empty: return "First run"
        case .create: return "New task"
        case .edit: return "Edit task"
        case .move: return "Move task"
        }
    }
}

struct ConsumerPlanningView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var screen: ConsumerPlanningScreen = .empty
    @State private var items: [PlanningWorkbenchItem] = []
    @State private var selectedID: UUID?
    @State private var draftTitle = ""
    @State private var draftStart = Calendar.current.startOfDay(for: Date())
    @State private var draftEnd = Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    @State private var draftPriority: PlanningWorkbenchItem.Priority = .medium
    @State private var dragOriginStart: Date?
    @State private var dragOriginEnd: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                introCard
                screenPicker

                switch screen {
                case .empty:
                    emptyState
                case .create:
                    taskEditor(isNew: true)
                case .edit:
                    taskEditor(isNew: false)
                case .move:
                    moveBoard
                }
            }
            .padding(24)
        }
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.background(for: colorScheme))
        .onChange(of: selectedID) { _, newID in
            guard let item = items.first(where: { $0.id == newID }) else { return }
            loadDraft(from: item)
        }
    }

    private var introCard: some View {
        consumerCard(title: "My plan", symbol: "person.crop.circle", tint: TimeBitePalette.green) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Plan it yourself")
                    .font(TimeBiteTypography.font(.title3, weight: .semibold))
                Text("A blank, personal workspace for goals you want to name, schedule, prioritize, and move forward. No imports or HealthKit setup required.")
                    .font(TimeBiteTypography.font(.callout))
                    .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
        }
    }

    private var screenPicker: some View {
        Picker("Wireframe screen", selection: $screen) {
            ForEach(ConsumerPlanningScreen.allCases) { screen in
                Text(screen.title).tag(screen)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var emptyState: some View {
        consumerCard(title: "Start with one thing", symbol: "plus.circle", tint: TimeBitePalette.sky) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Nothing here yet.")
                    .font(TimeBiteTypography.font(.title2, weight: .semibold))
                Text("Create a task or goal with a name, date range, and priority. You can refine the dates later by dragging its bar.")
                    .font(TimeBiteTypography.font(.callout))
                    .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                Button("Create your first task") {
                    beginNewTask()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func taskEditor(isNew: Bool) -> some View {
        consumerCard(title: isNew ? "Create task" : "Edit task", symbol: isNew ? "plus" : "slider.horizontal.3", tint: TimeBitePalette.sky) {
            VStack(alignment: .leading, spacing: 16) {
                Text(isNew ? "A small amount of structure makes the plan useful immediately." : "Adjust the dates directly, or use the Gantt drag handle below.")
                    .font(TimeBiteTypography.font(.callout))
                    .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                TextField("Task or goal name", text: $draftTitle)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 14) {
                    DatePicker("Starts", selection: $draftStart, displayedComponents: .date)
                    DatePicker("Ends", selection: $draftEnd, in: draftStart..., displayedComponents: .date)
                }

                Picker("Priority", selection: $draftPriority) {
                    ForEach(PlanningWorkbenchItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue.capitalized).tag(priority)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Spacer()
                    Button(isNew ? "Add to my plan" : "Save changes") {
                        saveDraft(isNew: isNew)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !isNew {
                    dateDragWireframe
                }
            }
        }
    }

    private var dateDragWireframe: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drag to shift dates")
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .tracking(TimeBiteTypography.eyebrowTracking)
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

            if let selectedID, let item = items.first(where: { $0.id == selectedID }) {
                let dayWidth: CGFloat = 28
                let duration = max(1, item.targetDate.timeIntervalSince(item.startDate) / 86_400.0)
                HStack(spacing: 12) {
                    Text(item.title)
                        .font(TimeBiteTypography.font(.caption, weight: .semibold))
                        .frame(width: 150, alignment: .leading)
                        .lineLimit(1)

                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(TimeBitePalette.border(for: colorScheme))
                            .frame(height: 1)
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(item.tint.gradient)
                            .frame(width: CGFloat(duration) * dayWidth, height: 22)
                            .overlay {
                                Text("drag")
                                    .font(TimeBiteTypography.font(.caption2, weight: .bold))
                                    .foregroundStyle(Color.black.opacity(0.7))
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if dragOriginStart == nil {
                                            dragOriginStart = item.startDate
                                            dragOriginEnd = item.targetDate
                                        }
                                        let deltaDays = Int((value.translation.width / dayWidth).rounded())
                                        shiftSelected(by: deltaDays)
                                    }
                                    .onEnded { _ in
                                        dragOriginStart = nil
                                        dragOriginEnd = nil
                                    }
                            )
                    }
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                }
                Text("Dates update in the fields above as the bar moves.")
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            } else {
                Text("Choose a task from the Move task screen to edit it here.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
        }
        .padding(14)
        .background(TimeBitePalette.background(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var moveBoard: some View {
        consumerCard(title: "Move through stages", symbol: "rectangle.3.group", tint: TimeBitePalette.violet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Drag a card into another column, or select a card and change its stage directly.")
                    .font(TimeBiteTypography.font(.callout))
                    .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), alignment: .top)], alignment: .leading, spacing: 12) {
                    ForEach(PlanningWorkbenchItem.BoardState.allCases, id: \.self) { stage in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(stage.rawValue.capitalized)
                                .font(TimeBiteTypography.font(.headline, weight: .semibold))
                                .tracking(TimeBiteTypography.sectionHeaderTracking)

                            ForEach(items.filter { $0.boardState == stage }) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(item.title)
                                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                                    Text("\(item.priority.rawValue.capitalized) priority")
                                        .font(TimeBiteTypography.font(.caption))
                                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                                    Picker("Stage", selection: stageBinding(for: item.id)) {
                                        ForEach(PlanningWorkbenchItem.BoardState.allCases, id: \.self) { option in
                                            Text(option.rawValue.capitalized).tag(option)
                                        }
                                    }
                                    .labelsHidden()
                                    .controlSize(.small)
                                    Button("Edit dates") {
                                        selectedID = item.id
                                        screen = .edit
                                    }
                                    .buttonStyle(.link)
                                }
                                .padding(12)
                                .background(TimeBitePalette.background(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .draggable(item.id.uuidString)
                            }

                            if items.filter({ $0.boardState == stage }).isEmpty {
                                Text("Drop tasks here")
                                    .font(TimeBiteTypography.font(.caption))
                                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                                    .padding(.vertical, 14)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .dropDestination(for: String.self) { values, _ in
                            moveItems(values, to: stage)
                        }
                    }
                }

                if items.isEmpty {
                    Text("Create a task first, then use this board to move it from Backlog to Active, Blocked, or Done.")
                        .font(TimeBiteTypography.font(.callout))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
            }
        }
    }

    private func consumerCard<Content: View>(title: String, symbol: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Text(title)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    .tracking(TimeBiteTypography.sectionHeaderTracking)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
        }
    }

    private func beginNewTask() {
        screen = .create
        draftTitle = ""
        draftStart = Calendar.current.startOfDay(for: Date())
        draftEnd = Calendar.current.date(byAdding: .day, value: 7, to: draftStart) ?? draftStart
        draftPriority = .medium
    }

    private func saveDraft(isNew: Bool) {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if isNew {
            let item = PlanningWorkbenchItem(
                id: UUID(), title: title, notes: "", kind: .project, boardState: .backlog,
                priority: draftPriority, startDate: draftStart, targetDate: draftEnd,
                sourceLabel: "Personal", accentSeed: title
            )
            items.append(item)
            selectedID = item.id
        } else if let selectedID, let index = items.firstIndex(where: { $0.id == selectedID }) {
            items[index].title = title
            items[index].startDate = draftStart
            items[index].targetDate = draftEnd
            items[index].priority = draftPriority
        }
        screen = .move
    }

    private func loadDraft(from item: PlanningWorkbenchItem) {
        draftTitle = item.title
        draftStart = item.startDate
        draftEnd = item.targetDate
        draftPriority = item.priority
    }

    private func stageBinding(for id: UUID) -> Binding<PlanningWorkbenchItem.BoardState> {
        Binding(
            get: { items.first(where: { $0.id == id })?.boardState ?? .backlog },
            set: { newStage in
                guard let index = items.firstIndex(where: { $0.id == id }) else { return }
                items[index].boardState = newStage
            }
        )
    }

    private func moveItems(_ values: [String], to stage: PlanningWorkbenchItem.BoardState) -> Bool {
        var didMove = false
        for value in values {
            guard let id = UUID(uuidString: value), let index = items.firstIndex(where: { $0.id == id }) else { continue }
            items[index].boardState = stage
            didMove = true
        }
        return didMove
    }

    private func shiftSelected(by days: Int) {
        guard let selectedID,
              let originStart = dragOriginStart,
              let originEnd = dragOriginEnd,
              let index = items.firstIndex(where: { $0.id == selectedID }) else { return }
        let calendar = Calendar.current
        items[index].startDate = calendar.date(byAdding: .day, value: days, to: originStart) ?? originStart
        items[index].targetDate = calendar.date(byAdding: .day, value: days, to: originEnd) ?? originEnd
        draftStart = items[index].startDate
        draftEnd = items[index].targetDate
    }
}

private extension PlanningWorkbenchItem.Priority {
    static var allCases: [Self] { [.low, .medium, .high, .urgent] }
}

private extension PlanningWorkbenchItem.BoardState {
    static var allCases: [Self] { [.backlog, .active, .blocked, .done] }
}
