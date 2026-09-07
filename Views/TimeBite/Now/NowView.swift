import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

private enum NowQuickCaptureFocusField {
    case sleepHours
    case action
}

struct NowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: NowWorkspaceViewModel
    @StateObject private var speechInput = NowSpeechDictationController()
    @StateObject private var health = HealthDataService.shared
    @State private var isCreatingCategory = false
    @State private var showingHealthSetup = false
    @State private var showingPhotoCaptureImporter = false
    @State private var didSleepToday = true
    @State private var sleepHoursText = "8"
    @State private var quickActionText = ""
    @State private var selectedSleepHours = 8
    @State private var collapsedProjectIDs = Set<UUID>()
    @FocusState private var quickCaptureFocus: NowQuickCaptureFocusField?
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
            syncSleepDraft()
            quickCaptureFocus = model.isSleepPromptVisible ? .sleepHours : .action
        }
        .onChange(of: model.isSleepPromptVisible) { _, isVisible in
            if isVisible {
                syncSleepDraft()
                quickCaptureFocus = .sleepHours
            } else {
                quickCaptureFocus = .action
            }
        }
        .onChange(of: speechInput.composedText) { _, newValue in
            quickActionText = newValue
        }
        .sheet(isPresented: $showingHealthSetup) {
            HealthSetupSheet()
        }
#if !os(watchOS)
        .fileImporter(
            isPresented: $showingPhotoCaptureImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await model.captureQuickActions(fromImageAt: url) }
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
#endif
    }

    @ViewBuilder
    private func workspaceContent(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            PrimaryNavigationBar(
                title: "Now",
                subtitle: "Fast capture, tiny-screen timers, and daily allocation"
            )

            if let errorMessage = model.errorMessage {
                errorBanner(errorMessage)
            }

            if health.snapshot != nil || health.message != nil || health.isAvailable {
                healthCard
            }

            captureFlowCard(now: now)
            compactTimerAndTaskCluster(now: now)
            checklistCard(now: now)
            weeklyPlanCard(now: now)
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

    private func captureFlowCard(now: Date) -> some View {
        DashboardCard(
            title: model.isSleepPromptVisible ? "Start the day" : "Create action",
            systemImage: "square.and.pencil",
            tint: TimeBitePalette.blue
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if model.isSleepPromptVisible {
                    sleepPromptSection
                    Divider()
                }

                quickActionSection(now: now)
            }
        }
    }

    @ViewBuilder
    private func actionTimerContent(now: Date) -> some View {
        let focusAction = model.activeAction ?? model.selectedAction
        let estimatedMinutes = focusAction.map { max(15, model.plannedMinutes(for: $0)) } ?? 30
        let actualMinutes = focusAction.map { model.actualMinutes(for: $0, now: now) } ?? 0
        let progress = ActivityProgressCalculator().calculate(completed: actualMinutes, planned: estimatedMinutes).normalizedProgress
        let session = model.activeSession

        VStack(alignment: .center, spacing: 12) {
            TimerDialView(
                progress: progress,
                accentColor: session == nil ? TimeBitePalette.blue : TimeBitePalette.green,
                primaryLabel: actualMinutes.actionClockDuration,
                secondaryLabel: focusAction.map { _ in "\(estimatedMinutes.actionClockDuration) planned" } ?? "Select an action",
                isRunning: session != nil,
                isEnabled: focusAction != nil,
                onLongPress: {
                    if let focusAction {
                        model.start(focusAction)
                    }
                }
            )
            .frame(width: 158, height: 158)

            Text(focusAction?.title ?? "Create an action")
                .font(TimeBiteTypography.font(.headline, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            hierarchyLine(for: focusAction)

            if session == nil {
                Button {
                    if let focusAction {
                        model.start(focusAction)
                    }
                } label: {
                    Label("Start action timer", systemImage: "play.fill")
                        .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .disabled(focusAction == nil)
            } else {
                LiveElapsedText(startDate: session?.startDate)
                    .font(TimeBiteTypography.font(.callout, weight: .medium))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                HStack(spacing: 10) {
                    Button {
                        if let focusAction {
                            model.markComplete(focusAction)
                        }
                    } label: {
                        Label("Complete action", systemImage: "checkmark.square")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        model.stopActiveSession()
                    } label: {
                        Label("Stop timer", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        model.clearActiveSession()
                    } label: {
                        Label("Clear timer", systemImage: "xmark.square")
                    }
                    .buttonStyle(.bordered)
                    .help("Reset the timer without completing the action.")
                }
            }

            Text(model.timerLongPressHint(for: focusAction, now: now))
                .font(TimeBiteTypography.font(.caption))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

            HStack(spacing: 10) {
                StatPill(label: "Estimate", value: estimatedMinutes.timeBiteDuration, tint: TimeBitePalette.blue)
                StatPill(label: "Actual", value: actualMinutes.timeBiteDuration, tint: TimeBitePalette.green)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var sleepPromptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Did you sleep today?")
                .font(TimeBiteTypography.font(.headline, weight: .semibold))

            Picker("Did you sleep today?", selection: Binding(
                get: { didSleepToday },
                set: { newValue in
                    didSleepToday = newValue
                    if newValue == false {
                        model.setSleepMinutes(0)
                    } else {
                        quickCaptureFocus = .sleepHours
                    }
                }
            )) {
                Text("Yes").tag(true)
                Text("No").tag(false)
            }
            .pickerStyle(.segmented)

            Text("How many hours?")
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .tracking(TimeBiteTypography.eyebrowTracking)
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

            HStack(spacing: 10) {
                Picker("Hours", selection: $selectedSleepHours) {
                    ForEach(1...23, id: \.self) { hours in
                        Text("\(hours)").tag(hours)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedSleepHours) { _, newValue in
                    sleepHoursText = "\(newValue)"
                    if didSleepToday {
                        model.setSleepMinutes(newValue * 60)
                    }
                }

                TextField("8", text: $sleepHoursText)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .focused($quickCaptureFocus, equals: .sleepHours)
                    .onChange(of: sleepHoursText) { _, newValue in
                        guard didSleepToday, let hours = parsedSleepHours(from: newValue) else { return }
                        selectedSleepHours = hours
                        model.setSleepMinutes(hours * 60)
                    }
            }

            HStack {
                Spacer(minLength: 0)
                Button("Use sleep") {
                    model.setSleepMinutes(selectedSleepHours * 60)
                    quickCaptureFocus = .action
                }
                .buttonStyle(.borderedProminent)
                .disabled(!didSleepToday)
            }

            Text("The sleep amount feeds today’s baseline before the first action starts.")
                .font(TimeBiteTypography.font(.caption))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
        }
    }

    private func quickActionSection(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Create action")
                .font(TimeBiteTypography.font(.headline, weight: .semibold))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TimeBitePalette.elevatedSurface(for: colorScheme))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(TimeBitePalette.border(for: colorScheme))
                    }
                    .frame(minHeight: 104)

                if quickActionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Type one action, dictate it, or paste a batch from another app.")
                        .font(TimeBiteTypography.font(.callout))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        .padding(12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: Binding(
                    get: { quickActionText },
                    set: { quickActionText = $0 }
                ))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 104)
                .focused($quickCaptureFocus, equals: .action)
                .dropDestination(for: String.self) { values, _ in
                    let droppedText = values.joined(separator: "\n")
                    guard !droppedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
                    if quickActionText.isEmpty {
                        quickActionText = droppedText
                    } else {
                        quickActionText += "\n" + droppedText
                    }
                    return true
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Button {
                        commitQuickActions()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(quickActionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Create action")
                    .help("Create action")

                    Button {
                        speechInput.toggleDictation(currentText: quickActionText)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(speechInput.isActive ? speechInput.buttonTint.opacity(0.15) : Color.clear)
                                .frame(width: 34, height: 34)

                            Image(systemName: "waveform.badge.mic")
                                .font(.system(size: 16, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(speechInput.buttonTint)
                                .scaleEffect(speechInput.state == .listening ? 1.08 : 1.0)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel(speechInput.isActive ? "Stop dictation" : "Start dictation")
                    .help(speechInput.isActive ? "Stop dictation" : "Start dictation")
                    .animation(.easeInOut(duration: 0.2), value: speechInput.state)

#if canImport(Vision)
                    Button {
                        showingPhotoCaptureImporter = true
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.bordered)
#endif

                    Spacer(minLength: 8)
                }

                if let statusText = speechInput.statusText {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(speechInput.buttonTint)
                            .frame(width: 7, height: 7)
                        Text(statusText)
                            .font(TimeBiteTypography.font(.caption))
                            .foregroundStyle(speechInput.buttonTint)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Paste, drop, or dictate.")
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
            }

            Divider()
            actionTimerContent(now: now)
        }
    }

    private func commitQuickActions() {
        if speechInput.isActive {
            speechInput.stopDictation()
            quickActionText = speechInput.composedText
        }
        let trimmed = quickActionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.captureQuickActions(from: trimmed)
        quickActionText = ""
        quickCaptureFocus = .action
    }

    private func compactTimerAndTaskCluster(now: Date) -> some View {
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                compactDailyTimerCard(now: now)
                routinePlanningCard
                compactTaskQueue(now: now)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    compactDailyTimerCard(now: now)
                    routinePlanningCard
                }
                compactTaskQueue(now: now)
            }

            VStack(alignment: .leading, spacing: 12) {
                compactDailyTimerCard(now: now)
                routinePlanningCard
                compactTaskQueue(now: now)
            }
        }
    }

    private func compactTaskQueue(now: Date) -> some View {
        let tasks = Array(model.incompleteActions.prefix(6))

        return DashboardCard(title: "Tasks", systemImage: "list.bullet", tint: TimeBitePalette.blue) {
            VStack(alignment: .leading, spacing: 6) {
                if tasks.isEmpty {
                    Text("Your captured tasks appear here.")
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                } else {
                    ForEach(tasks) { action in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(color(for: model.currentSelectionColor(for: action)))
                                .frame(width: 4, height: 28)

                            Button {
                                model.selectedActionID = action.id
                            } label: {
                                Text(action.title)
                                    .font(TimeBiteTypography.font(.caption, weight: .medium))
                                    .lineLimit(1)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                model.start(action)
                            } label: {
                                Image(systemName: model.activeAction?.id == action.id ? "play.fill" : "play.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(color(for: model.currentSelectionColor(for: action)))
                            }
                            .buttonStyle(.borderless)
                            .help("Start \(action.title)")
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 4)
                        .background(
                            model.selectedActionID == action.id
                                ? color(for: model.currentSelectionColor(for: action)).opacity(0.10)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
                if model.incompleteActions.count > tasks.count {
                    Text("+(model.incompleteActions.count - tasks.count) more")
                        .font(TimeBiteTypography.font(.caption2, weight: .semibold))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
            }
        }
        .frame(minWidth: 0, idealWidth: 180, maxWidth: 220)
    }

    private func compactDailyTimerCard(now: Date) -> some View {
        let lanes = model.dailyLanes(now: now)
        let plannedMinutes = lanes.reduce(0) { $0 + $1.plannedMinutes }
        let actualMinutes = lanes.reduce(0) { $0 + $1.actualMinutes }
        let sleepMinutes = model.sleepMinutesForToday

        return DashboardCard(title: "Daily timer", systemImage: "clock", tint: TimeBitePalette.green) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    SegmentedDayRing(
                        segments: dailyRingSegments(),
                        primaryLabel: plannedMinutes.timeBiteDuration,
                        secondaryLabel: "day",
                        color: color(for:)
                    )
                    .frame(width: 110, height: 110)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sleep is folded into the day baseline.")
                            .font(TimeBiteTypography.font(.headline, weight: .semibold))
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            StatPill(label: "Sleep", value: sleepMinutes.timeBiteDuration, tint: TimeBitePalette.violet)
                            StatPill(label: "Actual", value: actualMinutes.timeBiteDuration, tint: TimeBitePalette.sky)
                        }

                        Text("Planned \(plannedMinutes.timeBiteDuration) · remaining \(max(0, 24 * 60 - plannedMinutes).timeBiteDuration)")
                            .font(TimeBiteTypography.font(.caption))
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(lanes) { lane in
                            LaneSummaryRow(summary: lane, color: color(for: lane.colorToken))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(lanes) { lane in
                            LaneSummaryRow(summary: lane, color: color(for: lane.colorToken))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 270)
    }

    private func parsedSleepHours(from rawValue: String) -> Int? {
        guard let value = Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)),
              (1...23).contains(value) else { return nil }
        return value
    }

    private func syncSleepDraft() {
        didSleepToday = model.sleepMinutesForToday > 0
        selectedSleepHours = max(1, model.sleepMinutesForToday / 60)
        sleepHoursText = "\(selectedSleepHours)"
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

                    estimateWorkflowEditor

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
                    Text("Create Action")
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
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(goalSummary.projects) { project in
                                            projectSection(goalTitle: goalSummary.goal.title, project: project, now: now)
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
                            Text("Actions")
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

    private func dailyRingSegments() -> [TimeRingSegment] {
        let plans = model.routinePlans
        var segments = [TimeRingSegment(
            id: "sleep",
            title: "Sleep",
            startMinutes: 0,
            durationMinutes: model.sleepMinutesForToday,
            colorToken: .violet
        )]

        for plan in plans {
            let components = Calendar.current.dateComponents([.hour, .minute], from: plan.startDate)
            let startMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            let token: NowAllocationColorToken = switch plan.period {
            case .morning: .sky
            case .afternoon: .teal
            case .evening: .gold
            }
            segments.append(TimeRingSegment(
                id: plan.id.uuidString,
                title: plan.title,
                startMinutes: startMinutes,
                durationMinutes: Int(plan.endDate.timeIntervalSince(plan.startDate) / 60),
                colorToken: token
            ))
        }
        return segments
    }

    private var baselineCard: some View {
        let totalBaselineMinutes = model.preferences.baselineNeeds.reduce(0) { $0 + $1.estimateMinutes }
        let progress = min(Double(totalBaselineMinutes) / Double(24 * 60), 1)

        return DashboardCard(title: "Baseline day model", systemImage: "bed.double", tint: TimeBitePalette.gold) {
            VStack(alignment: .leading, spacing: 12) {
                ActivityRingView(
                    progress: progress,
                    accentColor: TimeBitePalette.gold,
                    primaryLabel: totalBaselineMinutes.timeBiteDuration,
                    secondaryLabel: "of 24 hours",
                    lineWidth: 12
                )
                .frame(width: 116, height: 116)

                Text("Every category stays editable and labeled as an estimate.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                ForEach(model.preferences.baselineNeeds) { need in
                    HStack(alignment: .top, spacing: 12) {
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

                            Text(need.notes)
                                .font(TimeBiteTypography.font(.caption))
                                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                        }

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 8) {
                            Stepper(
                                value: Binding(
                                    get: { need.estimateMinutes },
                                    set: { model.setBaselineMinutes(id: need.id, minutes: $0) }
                                ),
                                in: 0...720,
                                step: 15
                            ) {
                                Text(need.estimateMinutes.timeBiteDuration)
                            }
                            .labelsHidden()

                            Button("Set") {
                                model.applyBaselineNeed(id: need.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(TimeBitePalette.gold)
                            .controlSize(.small)
                            .help("Apply this baseline amount to today’s allocation.")
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

    private func projectSection(goalTitle: String, project: NowProjectSummary, now: Date) -> some View {
        let isExpanded = Binding(
            get: { !collapsedProjectIDs.contains(project.id) },
            set: { expanded in
                if expanded {
                    collapsedProjectIDs.remove(project.id)
                } else {
                    collapsedProjectIDs.insert(project.id)
                }
            }
        )
        let tint = project.actions.first.map { color(for: model.currentSelectionColor(for: $0)) } ?? TimeBitePalette.violet

        return DisclosureGroup(isExpanded: isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    StatPill(label: "Actual", value: project.actualMinutes.timeBiteDuration, tint: tint)
                    StatPill(label: "Planned", value: project.plannedMinutes.timeBiteDuration, tint: TimeBitePalette.sky)
                }

                ForEach(project.actions) { action in
                    ActionRow(
                        action: action,
                        goalTitle: goalTitle,
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
            .padding(.top, 8)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.project.title)
                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                    Text(goalTitle)
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }
                Spacer(minLength: 12)
                Text("\(project.actualMinutes.timeBiteDuration) / \(project.plannedMinutes.timeBiteDuration)")
                    .font(TimeBiteTypography.font(.caption2))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
            .padding(12)
            .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .tint(tint)
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

    private var estimateWorkflowEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Estimated time")
                    .font(TimeBiteTypography.font(.title3, weight: .semibold))
                Spacer()
                Picker("Estimate type", selection: $model.draftEstimateInputMode) {
                    ForEach(NowEstimateInputMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }

            if model.draftEstimateInputMode == .duration {
                durationEntryRow(
                    title: "Estimate",
                    hours: $model.draftEstimateHoursText,
                    minutes: $model.draftEstimateMinutesText
                )
            } else {
                HStack(spacing: 12) {
                    DatePicker("Start", selection: $model.draftEstimateStartDate, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $model.draftEstimateEndDate, displayedComponents: .hourAndMinute)
                }

                Text(model.draftEstimateEndDate > model.draftEstimateStartDate
                     ? "This range will be saved as the estimate and start/end window."
                     : "End time must be after the start time.")
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(model.draftEstimateEndDate > model.draftEstimateStartDate ? TimeBitePalette.secondaryText(for: colorScheme) : TimeBitePalette.gold)
            }

            durationEntryRow(
                title: "Actual",
                hours: $model.draftActualHoursText,
                minutes: $model.draftActualMinutesText
            )

            Text(model.draftEstimateInputMode == .duration ? "Enter the planned duration directly." : "The estimate uses the selected time window.")
                .font(TimeBiteTypography.font(.caption))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
        }
        .padding(12)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func durationEntryRow(title: String, hours: Binding<String>, minutes: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(TimeBiteTypography.font(.callout, weight: .medium))
            Spacer()
            TextField("0", text: hours)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 54)
            Text("hr")
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            TextField("00", text: minutes)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 54)
            Text("min")
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
        }
    }

    private var routinePlanningCard: some View {
        DashboardCard(title: "Routine planning", systemImage: "square.grid.3x3", tint: TimeBitePalette.violet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("AM, Midday, and Evening blocks are customizable, draggable, and linked to actions or projects.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                ForEach(model.routinePlans) { plan in
                    routineSection(plan)
                }
            }
        }
    }

    @ViewBuilder
    private func routineSection(_ plan: NowRoutinePlan) -> some View {
        let isValid = plan.endDate > plan.startDate

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    Text(plan.period.subtitle)
                        .font(TimeBiteTypography.font(.caption))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }

                Spacer()

                Text("\(plan.committedMinutes.timeBiteDuration) committed")
                    .font(TimeBiteTypography.font(.caption2, weight: .bold))
                    .tracking(TimeBiteTypography.eyebrowTracking)
                    .textCase(.uppercase)
            }

            HStack(spacing: 12) {
                DatePicker(
                    "Start",
                    selection: Binding(
                        get: { plan.startDate },
                        set: { model.setRoutinePlanTimes(id: plan.id, startDate: $0, endDate: plan.endDate) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "End",
                    selection: Binding(
                        get: { plan.endDate },
                        set: { model.setRoutinePlanTimes(id: plan.id, startDate: plan.startDate, endDate: $0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
            .labelsHidden()

            if !isValid {
                Text("End time must be after the start time.")
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(TimeBitePalette.gold)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(plan.blocks) { block in
                    routineBlockCard(plan: plan, block: block)
                }
            }
            .padding(.top, 2)
        }
        .padding(12)
        .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TimeBitePalette.border(for: colorScheme))
        )
        .dropDestination(for: String.self) { strings, _ in
            guard let rawID = strings.first, let blockID = UUID(uuidString: rawID) else { return false }
            model.moveRoutineBlock(blockID: blockID, to: plan.id)
            return true
        }
    }

    @ViewBuilder
    private func routineBlockCard(plan: NowRoutinePlan, block: NowRoutineBlock) -> some View {
        let color = color(for: block.category.tintToken)
        let actionLabel = model.actions.first(where: { $0.id == block.linkedActionID })?.title ?? "None"
        let projectLabel = model.projects.first(where: { $0.id == block.linkedProjectID })?.title ?? "None"

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
                    .frame(width: 14, height: 14)
                TextField(
                    "Routine block",
                    text: Binding(
                        get: { block.title },
                        set: { model.setRoutineBlockTitle(planID: plan.id, blockID: block.id, title: $0) }
                    )
                )
                .textFieldStyle(.plain)
                .font(TimeBiteTypography.font(.callout, weight: .semibold))
                Spacer()
                Text("\(block.durationMinutes.timeBiteDuration)")
                    .font(TimeBiteTypography.font(.caption2, weight: .bold))
            }

            HStack(spacing: 10) {
                Picker("Category", selection: Binding(
                    get: { block.category },
                    set: { model.setRoutineBlockCategory(planID: plan.id, blockID: block.id, category: $0) }
                )) {
                    ForEach(NowRoutineCategoryKind.allCases) { category in
                        Label(category.title, systemImage: category.symbolName).tag(category)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Stepper(
                    value: Binding(
                        get: { block.durationMinutes },
                        set: { model.setRoutineBlockDuration(planID: plan.id, blockID: block.id, durationMinutes: $0) }
                    ),
                    in: 15...720,
                    step: 15
                ) {
                    Text("Duration \(block.durationMinutes.timeBiteDuration)")
                }
            }

            HStack(spacing: 10) {
                Menu {
                    Button("None") {
                        model.setRoutineBlockLinkedAction(planID: plan.id, blockID: block.id, actionID: nil)
                    }
                    Divider()
                    ForEach(model.actions.prefix(6)) { action in
                        Button(action.title) {
                            model.setRoutineBlockLinkedAction(planID: plan.id, blockID: block.id, actionID: action.id)
                        }
                    }
                } label: {
                    Text("Action: \(actionLabel)")
                }

                Menu {
                    Button("None") {
                        model.setRoutineBlockLinkedProject(planID: plan.id, blockID: block.id, projectID: nil)
                    }
                    Divider()
                    ForEach(model.projects.prefix(6)) { project in
                        Button(project.title) {
                            model.setRoutineBlockLinkedProject(planID: plan.id, blockID: block.id, projectID: project.id)
                        }
                    }
                } label: {
                    Text("Project: \(projectLabel)")
                }

                Spacer()
            }
            .font(TimeBiteTypography.font(.caption))
        }
        .padding(12)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.28))
        )
        .draggable(block.id.uuidString)
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
                Text(action.title)
                    .font(TimeBiteTypography.font(.callout, weight: .semibold))
                    .strikethrough(action.isCompleted, color: TimeBitePalette.secondaryText(for: colorScheme))

                HStack(spacing: 10) {
                    Text("Actual \(actualMinutes.actionClockDuration)")
                    Text("\(max(0, plannedMinutes - actualMinutes).actionClockDuration) remaining")
                }
                .font(TimeBiteTypography.font(.caption2))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                .padding(.top, 4)

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
                        StatPill(label: "Status", value: action.status == .inbox ? "Ready" : action.status.rawValue.capitalized, tint: tint)
                    }
                }
            }

            Button(action: onStart) {
                Image(systemName: isRunning ? "play.fill" : "play.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .buttonStyle(.borderless)
            .disabled(action.isCompleted)
            .help(isRunning ? "Action is running" : "Start action")
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

private struct TimerDialView: View {
    @Environment(\.colorScheme) private var colorScheme
    let progress: Double
    let accentColor: Color
    let primaryLabel: String
    let secondaryLabel: String
    let isRunning: Bool
    let isEnabled: Bool
    let onLongPress: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(TimeBitePalette.elevatedSurface(for: colorScheme))

            Circle()
                .stroke(accentColor.opacity(0.16), style: StrokeStyle(lineWidth: 14, lineCap: .round))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

            VStack(spacing: 2) {
                Text(primaryLabel)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                Text(secondaryLabel)
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(width: 132, height: 60)
            .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(width: 158, height: 158)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: 0.8, maximumDistance: 18) {
            guard isEnabled else { return }
            onLongPress()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRunning ? "Action timer" : "Start action")
        .accessibilityHint(isRunning ? "The timer is already running." : "Press and hold the timer ring to start this action.")
    }
}

fileprivate extension Int {
    var actionClockDuration: String {
        String(format: "%02d:%02d", self / 60, self % 60)
    }
}

private struct SegmentedDayRing: View {
    @Environment(\.colorScheme) private var colorScheme
    let segments: [TimeRingSegment]
    let primaryLabel: String
    let secondaryLabel: String
    let color: (NowAllocationColorToken) -> Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(TimeBitePalette.border(for: colorScheme).opacity(0.55), lineWidth: 12)

            ForEach(segments) { segment in
                let start = Double(segment.startMinutes) / 1_440
                let end = min(start + Double(segment.durationMinutes) / 1_440, 1)
                if end > start {
                    Circle()
                        .trim(from: start, to: end)
                        .stroke(
                            color(segment.colorToken),
                            style: StrokeStyle(lineWidth: 12, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }

            VStack(spacing: 3) {
                Text(primaryLabel)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                Text(secondaryLabel)
                    .font(TimeBiteTypography.font(.caption2))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            }
            .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily time allocation")
        .accessibilityValue(segments.map { "\($0.title) \($0.durationMinutes.timeBiteDuration)" }.joined(separator: ", "))
    }
}

private struct SquareAllocationBadge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "checkmark.square")
                Text(title)
                    .font(TimeBiteTypography.font(.caption2, weight: .bold))
                    .tracking(TimeBiteTypography.eyebrowTracking)
                    .textCase(.uppercase)
            }
            .foregroundStyle(tint)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(tint)
                        Text(value)
                            .font(TimeBiteTypography.font(.title3, weight: .semibold))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.20), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
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
