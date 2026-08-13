import SwiftUI

struct CalendarActionSidebar: View {
    @ObservedObject var model: CalendarViewModel
    @State private var showingNewAction = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UNSCHEDULED ACTIONS")
                        .font(TimeBiteTypography.font(.caption2, weight: .bold))
                        .tracking(1.2)
                    Text("Drag work into time")
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { showingNewAction = true } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .help("New action")
                    .accessibilityLabel("New action")
            }

            Picker("Action filter", selection: $model.actionFilter) {
                ForEach(CalendarActionFilter.allCases) { filter in Text(filter.title).tag(filter) }
            }
            .labelsHidden()

            ScrollView {
                LazyVStack(spacing: 9) {
                    if model.filteredActions.isEmpty {
                        ContentUnavailableView("No matching actions", systemImage: "checkmark.square", description: Text("Change the filter or create an action."))
                            .frame(minHeight: 240)
                    } else {
                        ForEach(model.filteredActions) { action in
                            ActionScheduleCard(action: action, model: model)
                                .draggable(CalendarDragPayload(kind: .action, id: action.id)) {
                                    Text(action.title)
                                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                                        .padding(10)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                                }
                        }
                    }
                }
            }
        }
        .padding(16)
        .sheet(isPresented: $showingNewAction) {
            NewCalendarActionView { title, minutes, priority in
                model.addAction(title: title, estimatedMinutes: minutes, priority: priority)
            }
        }
    }
}

private struct ActionScheduleCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: Action
    @ObservedObject var model: CalendarViewModel
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "square")
                    .foregroundStyle(.secondary)
                Text(action.title)
                    .font(TimeBiteTypography.font(.body, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let priority = action.priority {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(priority == .high ? TimeBitePalette.gold : .secondary)
                        .help("\(priority.rawValue.capitalized) priority")
                }
            }
            HStack(spacing: 8) {
                if let duration = action.estimatedDuration {
                    Label(duration.calendarDuration, systemImage: "clock")
                } else {
                    Label(SchedulingDefaults.defaultBlockDuration.calendarDuration, systemImage: "clock.badge.questionmark")
                }
                if let project = model.projectTitle(for: action) { Label(project, systemImage: "folder") }
            }
            .font(TimeBiteTypography.font(.caption))
            .foregroundStyle(.secondary)
            if let goal = model.goalTitle(for: action) {
                Label(goal, systemImage: "target")
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(.secondary)
            }
            let count = model.scheduledCount(for: action)
            if count > 0 {
                Text("\(count) block\(count == 1 ? "" : "s") scheduled")
                    .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                    .foregroundStyle(TimeBitePalette.sky)
            }
        }
        .padding(12)
        .background(
            hovering ? TimeBitePalette.elevatedSurface(for: colorScheme) : TimeBitePalette.surface(for: colorScheme),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(hovering ? TimeBitePalette.sky.opacity(0.5) : TimeBitePalette.border(for: colorScheme)))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Action, \(action.title), estimated \((action.estimatedDuration ?? SchedulingDefaults.defaultBlockDuration).calendarDuration)")
        .help("Drag to schedule. The action remains in your list.")
    }
}

private struct NewCalendarActionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var estimatedMinutes = 30
    @State private var hasEstimate = true
    @State private var priority: ActionPriority?
    let onSave: (String, Int?, ActionPriority?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Action").font(TimeBiteTypography.font(.title2, weight: .semibold))
            TextField("What needs to be done?", text: $title)
            Toggle("Add time estimate", isOn: $hasEstimate)
            if hasEstimate {
                Stepper("Estimated: \(estimatedMinutes) minutes", value: $estimatedMinutes, in: 15...480, step: 15)
            }
            Picker("Priority", selection: $priority) {
                Text("No priority").tag(ActionPriority?.none)
                ForEach(ActionPriority.allCases, id: \.self) { value in Text(value.rawValue.capitalized).tag(Optional(value)) }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), hasEstimate ? estimatedMinutes : nil, priority)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}

extension TimeInterval {
    var calendarDuration: String {
        let minutes = Int(self / 60)
        if minutes >= 60, minutes % 60 == 0 { return "\(minutes / 60)h" }
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m" }
        return "\(minutes)m"
    }
}
