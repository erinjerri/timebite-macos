import SwiftUI

struct NowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: NowWorkspaceViewModel
    @StateObject private var health = HealthDataService.shared
    @State private var isCreatingCategory = false
    @State private var showingHealthSetup = false
    @AppStorage("timebite.healthSetupPresented.v1") private var healthSetupPresented = false

    init(repository: (any PlanningRepository)? = nil) {
        _model = StateObject(wrappedValue: NowWorkspaceViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                workspaceContent(now: context.date)
            }
        }
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.background(for: colorScheme))
        .navigationTitle("Now")
        .toolbarTitleDisplayMode(.automatic)
        .onAppear {
            if health.isAvailable && !healthSetupPresented {
                showingHealthSetup = true
                healthSetupPresented = true
            }
        }
        .sheet(isPresented: $showingHealthSetup) {
            HealthSetupSheet()
        }
    }

    @ViewBuilder
    private func workspaceContent(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            PrimaryNavigationBar(
                title: "Now",
                subtitle: "Real timer, clear next steps, and daily allocation"
            )

            if let errorMessage = model.errorMessage {
                errorBanner(errorMessage)
            }

            if health.snapshot != nil || health.message != nil || health.isAvailable {
                healthCard
            }

            actionComposerCard
            checklistCard(now: now)

            HStack(alignment: .top, spacing: 18) {
                liveCard(now: now)
                nextActionCard(now: now)
            }

            periodSummaryRow(now: now)

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 16) {
                allocationCard(now: now)
                weeklyPlanCard(now: now)
                baselineCard
                reflectionCard
            }
        }
        .padding(24)
    }

    private var healthCard: some View {
        DashboardCard(
            title: "Health snapshot",
            systemImage: "heart.text.square",
            tint: TimeBitePalette.green
        ) {
            HStack(alignment: .top, spacing: 18) {
                ActivityRingView(
                    progress: min(Double(health.snapshot?.stepsToday ?? 0) / 10_000, 1),
                    accentColor: TimeBitePalette.green,
                    primaryLabel: health.snapshot.map { "\($0.stepsToday)" } ?? "--",
                    secondaryLabel: "steps today",
                    lineWidth: 12
                )
                .frame(width: 116, height: 116)

                VStack(alignment: .leading, spacing: 8) {
                    Text(health.snapshot == nil ? "Health data can personalize your day once a snapshot is available." : "Today’s step snapshot is ready to inform the plan.")
                        .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    Text(health.isLoading ? "Connecting to Health..." : health.message ?? "Refresh Health data from your companion source or check availability if you are using a supported platform.")
                        .font(TimeBiteTypography.font(.callout))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    if let snapshot = health.snapshot {
                        HStack(spacing: 10) {
                            StatPill(
                                label: "Sleep",
                                value: sleepSummary(for: snapshot),
                                tint: TimeBitePalette.violet
                            )
                            if let activeEnergy = snapshot.activeEnergyKilocalories {
                                StatPill(
                                    label: "Calories",
                                    value: "\(Int(activeEnergy)) kcal",
                                    tint: TimeBitePalette.gold
                                )
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        Button(health.isAvailable ? "Refresh Health" : "Open setup") {
                            showingHealthSetup = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TimeBitePalette.green)
                        .disabled(health.isLoading)

                        if health.snapshot != nil {
                            Text("Cached snapshot saved")
                                .font(TimeBiteTypography.font(.caption))
                                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 340, maximum: 520), spacing: 16)]
    }

    private func sleepSummary(for snapshot: HealthSnapshot) -> String {
        guard let minutes = snapshot.sleepMinutes else { return "--" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(remainingMinutes)m"
    }

    @ViewBuilder
    private func liveCard(now: Date) -> some View {
        let focusAction = model.activeAction ?? model.selectedAction
        let estimatedMinutes = focusAction.map { max(15, model.plannedMinutes(for: $0)) } ?? 30
        let actualMinutes = focusAction.map { model.actualMinutes(for: $0, now: now) } ?? 0
        let progress = ActivityProgressCalculator().calculate(completed: actualMinutes, planned: estimatedMinutes).normalizedProgress
        let session = model.activeSession

        DashboardCard(
            title: session == nil ? "Ready to start" : "Live action",
            systemImage: "timer",
            tint: session == nil ? TimeBitePalette.blue : TimeBitePalette.green
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    ActivityRingView(
                        progress: progress,
                        accentColor: session == nil ? TimeBitePalette.blue : TimeBitePalette.green,
                        primaryLabel: "\(Int(progress * 100))%",
                        secondaryLabel: session == nil ? "Idle" : "Live",
                        lineWidth: 14
                    )
                    .frame(width: 142, height: 142)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(focusAction?.title ?? "Pick or create an action to begin timing.")
                            .font(TimeBiteTypography.font(.title3, weight: .semibold))
                        hierarchyLine(for: focusAction)
                        LiveElapsedText(startDate: session?.startDate)
                            .font(TimeBiteTypography.font(.callout, weight: .medium))
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        HStack(spacing: 10) {
                            StatPill(label: "Estimate", value: estimatedMinutes.timeBiteDuration, tint: TimeBitePalette.blue)
                            StatPill(label: "Actual", value: actualMinutes.timeBiteDuration, tint: TimeBitePalette.green)
                        }
                    }
                }

                if session == nil {
                    Button {
                        if let action = focusAction {
                            model.start(action)
                        }
                    } label: {
                        Label("Start timer", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(focusAction == nil)
                } else {
                    Picker("Completion choice", selection: $model.completionChoice) {
                        ForEach(NowActionCompletionChoice.allCases) { choice in
                            Text(choice == .complete ? "Complete action" : "Keep in progress").tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 10) {
                        Button {
                            model.stopActiveSession()
                        } label: {
                            Label("Stop timer", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            if let action = focusAction {
                                model.start(action)
                            }
                        } label: {
                            Label("Restart", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(focusAction == nil)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func nextActionCard(now: Date) -> some View {
        let nextAction = model.nextAction
        let estimatedMinutes = nextAction.map { max(15, model.plannedMinutes(for: $0)) } ?? 0
        let actualMinutes = nextAction.map { model.actualMinutes(for: $0, now: now) } ?? 0
        let progress = estimatedMinutes > 0
            ? ActivityProgressCalculator().calculate(completed: actualMinutes, planned: estimatedMinutes).normalizedProgress
            : 0

        DashboardCard(
            title: "Next action",
            systemImage: "arrow.right.circle",
            tint: TimeBitePalette.sky
        ) {
            if let nextAction {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        ActivityRingView(
                            progress: progress,
                            accentColor: TimeBitePalette.sky,
                            primaryLabel: "\(Int(progress * 100))%",
                            secondaryLabel: "Next",
                            lineWidth: 10
                        )
                        .frame(width: 92, height: 92)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(nextAction.title)
                                .font(TimeBiteTypography.font(.title3, weight: .semibold))
                            hierarchyLine(for: nextAction)
                            Text("\(estimatedMinutes.timeBiteDuration) estimate · \(actualMinutes.timeBiteDuration) actual")
                                .font(TimeBiteTypography.font(.callout))
                                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        }
                    }

                    Button {
                        model.start(nextAction)
                    } label: {
                        Label("Start next action", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView(
                    "No next action yet",
                    systemImage: "checklist",
                    description: Text("Create an action to make the next move obvious.")
                )
                .frame(minHeight: 180)
            }
        }
    }

    private var actionComposerCard: some View {
        DashboardCard(title: "Create action", systemImage: "checkmark.square", tint: TimeBitePalette.blue) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Turn today's intention into a goal, then choose the smallest next step.")
                    .font(TimeBiteTypography.font(.callout))
                    .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .bottom, spacing: 12) {
                        questionField("What is the goal you want to achieve today?", text: $model.draftGoalTitle, placeholder: "Write the goal")
                        Button {
                            model.createGoalDraft()
                        } label: {
                            Text("Create Goal")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TimeBitePalette.blue)
                        .disabled(model.draftGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("What kind of goal is it?")
                                .font(TimeBiteTypography.font(.title3, weight: .semibold))
                            Picker("Goal category", selection: $model.draftGoalCategoryID) {
                                Text("Choose a category").tag(UUID?.none)
                                ForEach(model.goalCategories) { category in
                                    Text(category.title).tag(Optional(category.id))
                                }
                            }
                            .labelsHidden()
                        }

                        Spacer(minLength: 8)
                        Button {
                            isCreatingCategory.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TimeBitePalette.blue)
                        .help("Create a category")
                    }

                    if isCreatingCategory {
                        HStack(spacing: 8) {
                            TextField("New category name", text: $model.draftNewCategoryTitle)
                            Button("Save") {
                                model.createGoalCategory()
                                isCreatingCategory = false
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.draftNewCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }

                    questionField("Project (optional)", text: $model.draftProjectTitle, placeholder: "Add a project if useful")

                    Text("What is the smallest possible next step, action, or task?")
                        .font(TimeBiteTypography.font(.title3, weight: .semibold))
                    ForEach(model.draftActionTitles.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            TextField(
                                "Write the next step",
                                text: Binding(
                                    get: { model.draftActionTitles[index] },
                                    set: { model.draftActionTitles[index] = $0 }
                                )
                            )
                            .textFieldStyle(.plain)
                            if model.draftActionTitles.count > 1 {
                                Button {
                                    model.removeDraftAction(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        model.addDraftAction()
                    } label: {
                        Label("Add another task", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button {
                    model.createAction()
                } label: {
                    Text("Create tasks and start timer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(TimeBitePalette.blue)
                .disabled(model.draftActionTitles.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            }
        }
    }

    private func checklistCard(now: Date) -> some View {
        DashboardCard(title: "Saved checklist", systemImage: "checklist", tint: TimeBitePalette.violet) {
            VStack(alignment: .leading, spacing: 16) {
                if model.goalSummaries.isEmpty && model.looseActions.isEmpty {
                    ContentUnavailableView(
                        "Nothing saved yet",
                        systemImage: "checklist",
                        description: Text("Create a goal and its next steps above and they will appear here as a simple checklist.")
                    )
                    .frame(minHeight: 160)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(model.goalSummaries.enumerated()), id: \.element.id) { index, goalSummary in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(goalSummary.goal.title)
                                            .font(TimeBiteTypography.font(.headline, weight: .semibold))
                                        Text("\(goalSummary.actualMinutes.timeBiteDuration) actual · \(goalSummary.plannedMinutes.timeBiteDuration) planned")
                                            .font(TimeBiteTypography.font(.caption))
                                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                                    }

                                    Spacer(minLength: 12)

                                    StatPill(
                                        label: "Goal",
                                        value: goalSummary.projects.isEmpty ? "Saved" : "\(goalSummary.projects.count) project\(goalSummary.projects.count == 1 ? "" : "s")",
                                        tint: TimeBitePalette.violet
                                    )
                                }

                                if !goalSummary.projects.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(goalSummary.projects) { project in
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 8) {
                                                    Text(project.project.title)
                                                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                                                    Spacer()
                                                    Text("\(project.actualMinutes.timeBiteDuration) / \(project.plannedMinutes.timeBiteDuration)")
                                                        .font(TimeBiteTypography.font(.caption2))
                                                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                                                }

                                                ForEach(project.actions) { action in
                                                    ActionRow(
                                                        action: action,
                                                        goalTitle: goalSummary.goal.title,
                                                        projectTitle: project.project.title,
                                                        actualMinutes: model.actualMinutes(for: action, now: now),
                                                        plannedMinutes: model.plannedMinutes(for: action),
                                                        tint: color(for: model.currentSelectionColor(for: action)),
                                                        isSelected: model.selectedActionID == action.id,
                                                        isRunning: model.activeAction?.id == action.id,
                                                        onSelect: {
                                                            model.selectedActionID = action.id
                                                        },
                                                        onStart: {
                                                            model.start(action)
                                                        },
                                                        onToggleComplete: { completed in
                                                            if completed {
                                                                model.markComplete(action)
                                                            } else {
                                                                model.markInProgress(action)
                                                            }
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }

                                if !goalSummary.looseActions.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Loose actions")
                                            .font(TimeBiteTypography.font(.caption2, weight: .bold))
                                            .tracking(TimeBiteTypography.eyebrowTracking)
                                            .textCase(.uppercase)
                                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                                        ForEach(goalSummary.looseActions) { action in
                                            ActionRow(
                                                action: action,
                                                goalTitle: goalSummary.goal.title,
                                                projectTitle: nil,
                                                actualMinutes: model.actualMinutes(for: action, now: now),
                                                plannedMinutes: model.plannedMinutes(for: action),
                                                tint: color(for: model.currentSelectionColor(for: action)),
                                                isSelected: model.selectedActionID == action.id,
                                                isRunning: model.activeAction?.id == action.id,
                                                onSelect: {
                                                    model.selectedActionID = action.id
                                                },
                                                onStart: {
                                                    model.start(action)
                                                },
                                                onToggleComplete: { completed in
                                                    if completed {
                                                        model.markComplete(action)
                                                    } else {
                                                        model.markInProgress(action)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }

                            if index < model.goalSummaries.count - 1 {
                                Divider()
                            }
                        }
                    }

                    if !model.looseActions.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Inbox actions")
                                .font(TimeBiteTypography.font(.headline, weight: .semibold))

                            ForEach(model.looseActions) { action in
                                ActionRow(
                                    action: action,
                                    goalTitle: nil,
                                    projectTitle: nil,
                                    actualMinutes: model.actualMinutes(for: action, now: now),
                                    plannedMinutes: model.plannedMinutes(for: action),
                                    tint: color(for: model.currentSelectionColor(for: action)),
                                    isSelected: model.selectedActionID == action.id,
                                    isRunning: model.activeAction?.id == action.id,
                                    onSelect: {
                                        model.selectedActionID = action.id
                                    },
                                    onStart: {
                                        model.start(action)
                                    },
                                    onToggleComplete: { completed in
                                        if completed {
                                            model.markComplete(action)
                                        } else {
                                            model.markInProgress(action)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func allocationCard(now: Date) -> some View {
        let summary = model.todayReflectionSummary(now: now)
        let planned = max(summary.plannedMinutes, 1)
        let progress = ActivityProgressCalculator().calculate(completed: summary.totalMinutes, planned: planned).normalizedProgress
        let lanes = model.dailyLanes(now: now)

        return DashboardCard(title: "Daily allocation", systemImage: "circle.grid.3x3", tint: TimeBitePalette.green) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 18) {
                    ActivityRingView(
                        progress: progress,
                        accentColor: TimeBitePalette.green,
                        primaryLabel: summary.totalMinutes.timeBiteDuration,
                        secondaryLabel: "actual",
                        lineWidth: 12
                    )
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Planned \(summary.plannedMinutes.timeBiteDuration) · actual \(summary.totalMinutes.timeBiteDuration)")
                            .font(TimeBiteTypography.font(.title3, weight: .semibold))
                        Text("Baseline, project targets, and remaining time are shown as editable lanes.")
                            .font(TimeBiteTypography.font(.callout))
                            .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(lanes) { lane in
                        LaneSummaryRow(summary: lane, color: color(for: lane.colorToken))
                    }
                }
            }
        }
    }

    private var baselineCard: some View {
        DashboardCard(title: "Baseline day model", systemImage: "bed.double", tint: TimeBitePalette.gold) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Every category stays editable and labeled as an estimate.")
                    .font(TimeBiteTypography.font(.callout))
                    .lineSpacing(TimeBiteTypography.bodyLineSpacing)
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                ForEach(model.preferences.baselineNeeds) { need in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(
                            "Need",
                            text: Binding(
                                get: { need.title },
                                set: { model.setBaselineTitle(id: need.id, title: $0) }
                            )
                        )
                        .textFieldStyle(.plain)
                        .font(TimeBiteTypography.font(.callout, weight: .semibold))

                        Stepper(
                            value: Binding(
                                get: { need.estimateMinutes },
                                set: { model.setBaselineMinutes(id: need.id, minutes: $0) }
                            ),
                            in: 0...720,
                            step: 15
                        ) {
                            HStack {
                                Text(need.notes)
                                    .font(TimeBiteTypography.font(.caption))
                                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                                Spacer()
                                Text("\(need.estimateMinutes) min")
                            }
                        }
                    }
                    .padding(12)
                    .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func weeklyPlanCard(now: Date) -> some View {
        let summary = model.weeklyAllocationSummary()

        return DashboardCard(title: "Weekly allocation", systemImage: "calendar.badge.clock", tint: TimeBitePalette.sky) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Picker("Mode", selection: Binding(
                        get: { model.preferences.allocationMode },
                        set: { model.setAllocationMode($0) }
                    )) {
                        ForEach(NowAllocationMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Spacer()

                    Stepper(
                        value: Binding(
                            get: { model.preferences.weeklyBudgetHours },
                            set: { model.setWeeklyBudgetHours($0) }
                        ),
                        in: 0...80,
                        step: 1
                    ) {
                        Text("Budget \(model.preferences.weeklyBudgetHours, format: .number.precision(.fractionLength(0)))h")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.preferences.weeklyAllocations) { allocation in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(
                                "Project",
                                text: Binding(
                                    get: { allocation.title },
                                    set: { model.setWeeklyAllocationTitle(id: allocation.id, title: $0) }
                                )
                            )
                            .textFieldStyle(.plain)
                            .font(TimeBiteTypography.font(.callout, weight: .semibold))

                            HStack(spacing: 12) {
                                if model.preferences.allocationMode == .percentage {
                                    Stepper(
                                        value: Binding(
                                            get: { allocation.percentage },
                                            set: { model.setWeeklyAllocationPercentage(id: allocation.id, percentage: $0) }
                                        ),
                                        in: 0...100,
                                        step: 1
                                    ) {
                                        Text("\(allocation.percentage, format: .number.precision(.fractionLength(0)))%")
                                    }
                                } else {
                                    Stepper(
                                        value: Binding(
                                            get: { allocation.weeklyHours },
                                            set: { model.setWeeklyAllocationHours(id: allocation.id, hours: $0) }
                                        ),
                                        in: 0...80,
                                        step: 0.5
                                    ) {
                                        Text("\(allocation.weeklyHours, format: .number.precision(.fractionLength(1)))h")
                                    }
                                }

                                Spacer()

                                Text("\(dailyTargetText(for: allocation)) / day")
                                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                            }

                            Text(allocation.notes)
                                .font(TimeBiteTypography.font(.caption))
                                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        }
                        .padding(12)
                        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                HStack(spacing: 12) {
                    StatPill(label: "Planned", value: summary.plannedMinutes.timeBiteDuration, tint: TimeBitePalette.sky)
                    StatPill(label: "Remaining", value: summary.unallocatedMinutes.timeBiteDuration, tint: TimeBitePalette.green)
                    if summary.overflowMinutes > 0 {
                    StatPill(label: "Overflow", value: summary.overflowMinutes.timeBiteDuration, tint: TimeBitePalette.gold)
                    }
                }
            }
        }
    }

    private var reflectionCard: some View {
        DashboardCard(title: "Daily reflection", systemImage: "text.quote", tint: TimeBitePalette.violet) {
            VStack(alignment: .leading, spacing: 14) {
                let summary = model.todayReflectionSummary(now: .now)
                HStack(spacing: 12) {
                    StatPill(label: "AM", value: summary.amMinutes.timeBiteDuration, tint: TimeBitePalette.gold)
                    StatPill(label: "PM", value: summary.pmMinutes.timeBiteDuration, tint: TimeBitePalette.violet)
                    StatPill(label: "Total", value: summary.totalMinutes.timeBiteDuration, tint: TimeBitePalette.green)
                }

                TextEditor(text: Binding(
                    get: { model.preferences.reflection.amReflection ?? "" },
                    set: { model.setReflectionAM($0) }
                ))
                .frame(minHeight: 82)
                .padding(10)
                .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("AM reflection")
                        .font(TimeBiteTypography.font(.caption2, weight: .bold))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        .padding(.leading, 16)
                        .padding(.top, 12)
                }

                TextEditor(text: Binding(
                    get: { model.preferences.reflection.pmReflection ?? "" },
                    set: { model.setReflectionPM($0) }
                ))
                .frame(minHeight: 82)
                .padding(10)
                .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("PM reflection")
                        .font(TimeBiteTypography.font(.caption2, weight: .bold))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        .padding(.leading, 16)
                        .padding(.top, 12)
                }
            }
        }
    }

    private func periodSummaryRow(now: Date) -> some View {
        let summary = model.todayReflectionSummary(now: now)
        let halfPlanned = max(1, summary.plannedMinutes / 2)
        let amProgress = ActivityProgressCalculator().calculate(completed: summary.amMinutes, planned: halfPlanned).normalizedProgress
        let pmProgress = ActivityProgressCalculator().calculate(completed: summary.pmMinutes, planned: max(1, summary.plannedMinutes - halfPlanned)).normalizedProgress

        return HStack(alignment: .top, spacing: 16) {
            SummaryRingCard(
                title: "AM Summary",
                text: "Morning actual time against the first half of today's plan.",
                progress: amProgress,
                tint: TimeBitePalette.gold,
                label: "AM"
            )
            SummaryRingCard(
                title: "PM Summary",
                text: "Afternoon actual time against the second half of today's plan.",
                progress: pmProgress,
                tint: TimeBitePalette.violet,
                label: "PM"
            )
        }
    }

    private func errorBanner(_ text: String) -> some View {
        Text(text)
            .font(TimeBiteTypography.font(.callout))
            .foregroundStyle(TimeBitePalette.gold)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TimeBitePalette.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func hierarchyLine(for action: Action?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let action {
                if let projectTitle = model.projects.first(where: { $0.id == action.projectID })?.title {
                    Text(projectTitle)
                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
                if let goalTitle = model.goals.first(where: { $0.id == action.goalID })?.title {
                    Text(goalTitle)
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
                Text(action.status.rawValue.capitalized)
                    .font(TimeBiteTypography.font(.caption2, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(TimeBiteTypography.eyebrowTracking)
                    .foregroundStyle(color(for: model.currentSelectionColor(for: action)))
            } else {
                Text("No action selected yet")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
        }
    }

    private func dailyTargetText(for allocation: WeeklyAllocationPreset) -> String {
        let minutes = model.preferences.allocationMode == .percentage
            ? Int((model.preferences.weeklyBudgetHours * 60) * (allocation.percentage / 100.0) / 7.0)
            : Int(allocation.weeklyHours * 60 / 7.0)
        return minutes.timeBiteDuration
    }

    private func questionField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(TimeBiteTypography.font(.title3, weight: .semibold))
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(TimeBiteTypography.font(.callout))
        }
    }

    private func color(for token: NowAllocationColorToken) -> Color {
        switch token {
        case .blue: TimeBitePalette.blue
        case .green: TimeBitePalette.green
        case .gold: TimeBitePalette.gold
        case .violet: TimeBitePalette.violet
        case .teal: TimeBitePalette.teal
        case .sky: TimeBitePalette.sky
        case .neutral: TimeBitePalette.secondaryText(for: colorScheme)
        }
    }
}

private struct ActionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: Action
    let goalTitle: String?
    let projectTitle: String?
    let actualMinutes: Int
    let plannedMinutes: Int
    let tint: Color
    let isSelected: Bool
    let isRunning: Bool
    let onSelect: () -> Void
    let onStart: () -> Void
    let onToggleComplete: (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                onToggleComplete(!action.isCompleted)
            } label: {
                Image(systemName: action.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(action.isCompleted ? tint : TimeBitePalette.secondaryText(for: colorScheme))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(action.title)
                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                        .strikethrough(action.isCompleted, color: TimeBitePalette.secondaryText(for: colorScheme))
                    Spacer(minLength: 12)
                    Text("\(plannedMinutes.timeBiteDuration) planned")
                        .font(TimeBiteTypography.font(.caption2))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }

                if let projectTitle {
                    Text(projectTitle)
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
                if let goalTitle {
                    Text(goalTitle)
                        .font(TimeBiteTypography.font(.caption2))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }

                HStack(spacing: 8) {
                        StatPill(label: "Actual", value: actualMinutes.timeBiteDuration, tint: tint)
                    if action.isCompleted {
                        StatPill(label: "Status", value: "Done", tint: tint)
                    } else if isRunning {
                        StatPill(label: "Status", value: "Running", tint: tint)
                    } else {
                        StatPill(label: "Status", value: action.status.rawValue.capitalized, tint: tint)
                    }
                }
            }

            VStack(spacing: 8) {
                Button(action: onStart) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.bordered)
                .disabled(isRunning)

            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? tint.opacity(0.10) : TimeBitePalette.elevatedSurface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? tint.opacity(0.35) : TimeBitePalette.border(for: colorScheme), lineWidth: 1)
        )
    }
}

private struct LaneSummaryRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let summary: NowLaneSummary
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(summary.title)
                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                }
                Spacer(minLength: 12)
                Text("\(summary.actualMinutes.timeBiteDuration) / \(summary.plannedMinutes.timeBiteDuration)")
                    .font(TimeBiteTypography.font(.caption2))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }

            ProgressView(value: Double(min(summary.actualMinutes, summary.plannedMinutes)), total: Double(max(summary.plannedMinutes, 1)))
                .tint(color)

            HStack(spacing: 8) {
                Text(summary.subtitle)
                if summary.remainingMinutes > 0 {
                    Text("\(summary.remainingMinutes.timeBiteDuration) remaining")
                }
                if summary.overflowMinutes > 0 {
                    Text("\(summary.overflowMinutes.timeBiteDuration) overflow")
                        .foregroundStyle(TimeBitePalette.gold)
                }
            }
            .font(TimeBiteTypography.font(.caption))
            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
        }
        .padding(10)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SummaryRingCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let text: String
    let progress: Double
    let tint: Color
    let label: String

    var body: some View {
        DashboardCard(title: title, systemImage: "circle.dotted", tint: tint) {
            HStack(alignment: .center, spacing: 16) {
                ActivityRingView(
                    progress: progress,
                    accentColor: tint,
                    primaryLabel: "\(Int(progress * 100))%",
                    secondaryLabel: label,
                    lineWidth: 9
                )
                .frame(width: 92, height: 92)

                Text(text)
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct StatPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(TimeBiteTypography.font(.caption2, weight: .bold))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            Text(value)
                .font(TimeBiteTypography.font(.callout, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LiveElapsedText: View {
    let startDate: Date?

    var body: some View {
        if let startDate {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(formattedElapsed(from: startDate, to: context.date))
            }
        } else {
            Text("Pick an action to begin timing.")
                .lineSpacing(TimeBiteTypography.bodyLineSpacing)
        }
    }

    private func formattedElapsed(from startDate: Date, to date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: startDate, to: date) ?? "00:00"
    }
}

struct DashboardCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content

    init(title: String, systemImage: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    .tracking(TimeBiteTypography.sectionHeaderTracking)
                Spacer(minLength: 0)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
        )
    }
}

#Preview {
    let store = PlanningStore.timelinePreview()
    return NowView(repository: InMemoryPlanningRepository(store: store))
        .frame(width: 1500, height: 1200)
}
