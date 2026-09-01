import SwiftUI

struct CalendarActionSidebar: View {
    @ObservedObject var model: CalendarViewModel
    @State private var showingNewAction = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UNSCHEDULED ACTIONS")
                        .font(TimeBiteTypography.font(.caption2, weight: .bold))
                        .tracking(TimeBiteTypography.eyebrowTracking)
                    Text("Drag work into time")
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Paste List / Brain Dump") { model.showingBulkCapture = true }
                    .buttonStyle(.bordered)
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
                        ContentUnavailableView(
                            "No matching actions",
                            systemImage: "checkmark.square",
                            description: Text("Change the filter or create an action.")
                        )
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

            if !model.suggestedPlanningBlocks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested blocks")
                        .font(TimeBiteTypography.font(.caption2, weight: .bold))
                        .tracking(TimeBiteTypography.sectionHeaderTracking)
                    ForEach(model.suggestedPlanningBlocks.prefix(3)) { suggestion in
                        Button {
                            model.scheduleSuggestion(suggestion)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.action.title).frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(suggestion.block.startDate.formatted(date: .omitted, time: .shortened)) · \(suggestion.block.plannedDuration.calendarDuration)")
                                    .font(TimeBiteTypography.font(.caption2))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(TimeBitePalette.border(for: colorScheme)))
                    }
                }
            }
        }
        .padding(16)
        .sheet(isPresented: $model.showingBulkCapture) {
            BulkCaptureView(model: model)
                .frame(width: 860, height: 760)
        }
        .sheet(isPresented: $showingNewAction) {
            NewCalendarActionView { title, minutes, priority in
                model.addAction(title: title, estimatedMinutes: minutes, priority: priority)
            }
        }
        .sheet(item: $model.estimatePrompt) { prompt in
            EstimateFeedbackView(prompt: prompt, onAccept: {
                model.recordEstimateFeedback(accepted: true)
            }, onReject: { minutes in
                model.recordEstimateFeedback(accepted: false, alternative: minutes)
            })
            .frame(width: 420, height: 280)
        }
        .sheet(item: $model.selectedCalendarSuggestion) { suggestion in
            CalendarSuggestionConfirmationView(
                suggestion: suggestion,
                onYes: { model.confirmSchedulingSuggestion() },
                onNo: { model.declineSchedulingSuggestion() },
                onMove: { model.moveSchedulingSuggestion() }
            )
            .frame(width: 560, height: 320)
        }
    }
}

private struct BulkCaptureView: View {
    @ObservedObject var model: CalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paste List / Brain Dump").font(TimeBiteTypography.font(.title2, weight: .semibold))
            Text("Paste messy notes, task lists, or half-formed thoughts. We will parse them into reviewable candidates.")
                .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                .foregroundStyle(.secondary)
            TextEditor(text: $model.bulkCaptureText)
                .font(TimeBiteTypography.font(.body))
                .padding(10)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
            HStack {
                Button("Parse") { model.parseBulkCapture() }
                Spacer()
                Button("Add Selected") { model.importBulkCapture() }
                    .buttonStyle(.borderedProminent)
            }
            List {
                ForEach($model.bulkCaptureResult.candidates) { $candidate in
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $candidate.isSelected) {
                            TextField("Task", text: $candidate.title)
                        }
                        HStack {
                            Picker("Type", selection: $candidate.kind) {
                                ForEach(CaptureItemKind.allCases, id: \.self) { kind in
                                    Text(kind.rawValue.capitalized).tag(kind)
                                }
                            }
                            Picker("Life Area", selection: Binding(
                                get: { candidate.lifeArea ?? .other },
                                set: { candidate.lifeArea = $0 }
                            )) {
                                Text("Choose area").tag(LifeArea.other)
                                ForEach(LifeArea.allCases) { area in Text(area.title).tag(area) }
                            }
                            Picker("Priority", selection: Binding(
                                get: { candidate.priority ?? .medium },
                                set: { candidate.priority = $0 }
                            )) {
                                Text("Medium").tag(ActionPriority.medium)
                                ForEach(ActionPriority.allCases, id: \.self) { priority in Text(priority.rawValue.capitalized).tag(priority) }
                            }
                        }
                        HStack {
                            Text("Estimated: \(candidate.estimatedMinutes.map { "\($0) min" } ?? "Need estimate")")
                            Spacer()
                            Text("Confidence \(Int(candidate.confidence * 100))%")
                        }
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(.secondary)
                        if candidate.requiresLifeAreaSelection {
                            Text("Choose area").foregroundStyle(TimeBitePalette.gold)
                        }
                        if candidate.requiresGoalSelection {
                            Text("Choose goal").foregroundStyle(TimeBitePalette.gold)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(18)
        .onAppear { model.parseBulkCapture() }
    }
}

private struct EstimateFeedbackView: View {
    let prompt: EstimatePrompt
    let onAccept: () -> Void
    let onReject: (Int) -> Void
    @State private var overrideMinutes = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(prompt.title).font(TimeBiteTypography.font(.title3, weight: .semibold))
            Text("Estimated: \(prompt.estimatedMinutes) min")
            Text("Is this realistic?")
                .lineSpacing(TimeBiteTypography.bodyLineSpacing)
            HStack {
                Button("Yes") { onAccept() }
                Button("No") { onReject(overrideMinutes) }
                Spacer()
            }
            HStack {
                Button("Shorter") { overrideMinutes = max(15, prompt.estimatedMinutes - 15) }
                Button("Longer") { overrideMinutes = prompt.estimatedMinutes + 15 }
                Stepper("Enter time: \(overrideMinutes) min", value: $overrideMinutes, in: 15...480, step: 15)
            }
        }
        .padding(24)
    }
}

private struct CalendarSuggestionConfirmationView: View {
    let suggestion: ScheduledSuggestion
    let onYes: () -> Void
    let onNo: () -> Void
    let onMove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested block").font(TimeBiteTypography.font(.title3, weight: .semibold))
            Text(suggestion.action.title)
            Text("Estimated: \(suggestion.block.plannedDuration.calendarDuration)")
            Text(suggestion.reason)
                .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                .foregroundStyle(.secondary)
            HStack {
                Button("Yes") { onYes() }.buttonStyle(.borderedProminent)
                Button("No") { onNo() }
                Button("Move") { onMove() }
            }
        }
        .padding(24)
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
