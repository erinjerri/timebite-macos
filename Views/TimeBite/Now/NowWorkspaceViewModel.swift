import Combine
import Foundation

struct NowLaneSummary: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var subtitle: String
    var plannedMinutes: Int
    var actualMinutes: Int
    var colorToken: NowAllocationColorToken
    var isBaseline: Bool

    var remainingMinutes: Int {
        max(0, plannedMinutes - actualMinutes)
    }

    var overflowMinutes: Int {
        max(0, actualMinutes - plannedMinutes)
    }
}

struct NowProjectSummary: Identifiable, Hashable, Sendable {
    var id: UUID { project.id }
    var project: Project
    var actualMinutes: Int
    var plannedMinutes: Int
    var actions: [Action]
}

struct NowGoalSummary: Identifiable, Hashable, Sendable {
    var id: UUID { goal.id }
    var goal: Goal
    var actualMinutes: Int
    var plannedMinutes: Int
    var projects: [NowProjectSummary]
    var looseActions: [Action]
}

struct NowReflectionSummary: Hashable, Sendable {
    var amMinutes: Int
    var pmMinutes: Int
    var totalMinutes: Int
    var plannedMinutes: Int
}

final class LocalNowWorkspacePreferencesStore {
    private static let key = "timebite.nowWorkspacePreferences.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> NowWorkspacePreferences {
        guard let data = defaults.data(forKey: Self.key),
              let preferences = try? decoder.decode(NowWorkspacePreferences.self, from: data),
              preferences.schemaVersion == NowWorkspacePreferences.currentSchemaVersion else {
            return NowWorkspacePreferences()
        }
        return preferences
    }

    func save(_ preferences: NowWorkspacePreferences) {
        defaults.set(try? encoder.encode(preferences), forKey: Self.key)
    }
}

@MainActor
final class NowWorkspaceViewModel: ObservableObject {
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var projects: [Project] = []
    @Published private(set) var actions: [Action] = []
    @Published private(set) var sessions: [FocusSession] = []
    @Published var preferences: NowWorkspacePreferences
    @Published var draftGoalTitle = ""
    @Published var draftGoalCategoryID: UUID?
    @Published var draftNewCategoryTitle = ""
    @Published var draftProjectTitle = ""
    @Published var draftActionTitles = [""]
    @Published var draftEstimateInputMode: NowEstimateInputMode = .duration
    @Published var draftEstimateMinutes = 45
    @Published var draftEstimateStartDate = Date()
    @Published var draftEstimateEndDate = Date().addingTimeInterval(45 * 60)
    @Published var selectedActionID: UUID?
    @Published private(set) var routinePlans: [NowRoutinePlan] = []
    @Published private(set) var lastTimerEvent: NowTimerEvent?
    @Published private(set) var lastTimerActionID: UUID?
    @Published var errorMessage: String?

    private let repository: any PlanningRepository
    private let preferencesStore: LocalNowWorkspacePreferencesStore
    private let categoryStore: LocalGoalCategoryStore
    private let calendar: Calendar
    private let now: () -> Date
    private let defaultEstimateMinutes = Int(SchedulingDefaults.defaultBlockDuration / 60)

    init(
        repository: (any PlanningRepository)? = nil,
        preferencesStore: LocalNowWorkspacePreferencesStore? = nil,
        categoryStore: LocalGoalCategoryStore? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        let preferencesStore = preferencesStore ?? LocalNowWorkspacePreferencesStore()
        self.repository = repository ?? LocalPlanningRepository()
        self.preferencesStore = preferencesStore
        self.categoryStore = categoryStore ?? LocalGoalCategoryStore()
        self.calendar = calendar
        self.now = now
        self.preferences = preferencesStore.load()
        if self.preferences.weeklyAllocations.isEmpty || self.preferences.baselineNeeds.isEmpty {
            self.preferences = NowWorkspacePreferences()
            preferencesStore.save(self.preferences)
        }
        reload()
        if routinePlans.isEmpty {
            routinePlans = makeDefaultRoutinePlans(
                actions: actions,
                projects: projects,
                now: now(),
                calendar: calendar
            )
        }
    }

    var goalCategories: [GoalCategory] { categoryStore.load() }

    var draftActionTitle: String {
        get { draftActionTitles.first ?? "" }
        set {
            if draftActionTitles.isEmpty { draftActionTitles = [newValue] }
            else { draftActionTitles[0] = newValue }
        }
    }

    func addDraftAction() {
        draftActionTitles.append("")
    }

    func removeDraftAction(at index: Int) {
        guard draftActionTitles.count > 1, draftActionTitles.indices.contains(index) else { return }
        draftActionTitles.remove(at: index)
    }

    func createGoalCategory() {
        let title = draftNewCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        var categories = categoryStore.load()
        if let existing = categories.first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
            draftGoalCategoryID = existing.id
        } else {
            let category = GoalCategory(title: title)
            categories.append(category)
            categoryStore.save(categories)
            draftGoalCategoryID = category.id
        }
        draftNewCategoryTitle = ""
        objectWillChange.send()
    }

    func createGoalDraft() {
        let title = draftGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            _ = try upsertGoal(title: title, categoryID: draftGoalCategoryID)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var activeSession: FocusSession? {
        sessions
            .filter { $0.status == .active }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    var activeAction: Action? {
        guard let activeSession, let actionID = activeSession.actionID else { return nil }
        return actions.first(where: { $0.id == actionID })
    }

    var nextAction: Action? {
        incompleteActions.sorted(by: actionSort).first
    }

    var incompleteActions: [Action] {
        actions.filter { $0.status != .completed && $0.status != .cancelled }
    }

    var selectedAction: Action? {
        if let selectedActionID, let selected = actions.first(where: { $0.id == selectedActionID }) {
            return selected
        }
        return activeAction ?? nextAction
    }

    var goalSummaries: [NowGoalSummary] {
        return goals.sorted { $0.createdAt < $1.createdAt }.map { goal in
            let goalProjects = projects
                .filter { $0.goalID == goal.id }
                .sorted { $0.createdAt < $1.createdAt }

            let summaries = goalProjects
                .map { project in
                    let projectActions = actions.filter { $0.projectID == project.id }
                    return NowProjectSummary(
                        project: project,
                        actualMinutes: actualMinutes(for: projectActions, now: now()),
                        plannedMinutes: plannedMinutes(for: projectActions),
                        actions: projectActions.sorted(by: actionSort)
                    )
                }

            let goalActions = actions.filter { $0.goalID == goal.id && $0.projectID == nil }.sorted(by: actionSort)
            let projectActions = summaries.flatMap { $0.actions }
            let combinedActions = goalActions + projectActions
            return NowGoalSummary(
                goal: goal,
                actualMinutes: actualMinutes(for: combinedActions, now: now()),
                plannedMinutes: plannedMinutes(for: combinedActions),
                projects: summaries,
                looseActions: goalActions
            )
        }
        .filter { !$0.projects.isEmpty || !$0.looseActions.isEmpty }
    }

    var looseActions: [Action] {
        actions.filter { $0.goalID == nil && $0.projectID == nil }.sorted(by: actionSort)
    }

    func reload() {
        do {
            goals = try repository.goals()
            projects = try repository.projects()
            actions = try repository.actions()
            sessions = try repository.focusSessions().sorted { $0.startDate > $1.startDate }
            if selectedActionID == nil || actions.contains(where: { $0.id == selectedActionID }) == false {
                selectedActionID = activeAction?.id ?? nextAction?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createAction() {
        let titles = draftActionTitles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !titles.isEmpty else { return }

        do {
            let trimmedGoal = draftGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedProject = draftProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let estimate = try validatedDraftEstimate()

            let goal = trimmedGoal.isEmpty ? nil : try upsertGoal(title: trimmedGoal, categoryID: draftGoalCategoryID)
            let project = trimmedProject.isEmpty ? nil : try upsertProject(title: trimmedProject, goalID: goal?.id)
            let savedActions = try titles.map { title in
                let action = Action(
                    goalID: goal?.id,
                    projectID: project?.id,
                    title: title,
                    estimatedDuration: estimate.duration.map { Double($0) },
                    startDate: estimate.startDate,
                    targetDate: estimate.endDate,
                    status: .planned
                )
                try repository.save(action)
                return action
            }
            if let firstAction = savedActions.first {
                selectedActionID = firstAction.id
                start(firstAction)
            }
            draftActionTitle = ""
            draftProjectTitle = ""
            draftGoalTitle = ""
            draftGoalCategoryID = nil
            draftActionTitles = [""]
            draftEstimateMinutes = defaultEstimateMinutes
            draftEstimateInputMode = .duration
            draftEstimateStartDate = now()
            draftEstimateEndDate = now().addingTimeInterval(Double(defaultEstimateMinutes) * 60)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func start(_ action: Action) {
        do {
            if let activeSession, activeSession.actionID != action.id {
                try finalize(activeSession: activeSession, actualDuration: elapsedDuration(for: activeSession, now: now()), sessionStatus: .completed, actionStatus: .inProgress)
                lastTimerEvent = .stopped
                lastTimerActionID = activeSession.actionID
            }
            let session = FocusSession(actionID: action.id, startDate: now(), status: .active)
            try repository.save(session)
            selectedActionID = action.id
            lastTimerEvent = .running
            lastTimerActionID = action.id
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopActiveSession() {
        do {
            guard let activeSession else { return }
            try finalize(
                activeSession: activeSession,
                actualDuration: elapsedDuration(for: activeSession, now: now()),
                sessionStatus: .completed,
                actionStatus: .inProgress
            )
            lastTimerEvent = .stopped
            lastTimerActionID = activeSession.actionID
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearActiveSession() {
        do {
            guard let activeSession else { return }
            let actionStatus = activeSession.actionID.flatMap { actionID in
                actions.first(where: { $0.id == actionID })?.status
            } ?? .inProgress
            try finalize(
                activeSession: activeSession,
                actualDuration: 0,
                sessionStatus: .cancelled,
                actionStatus: actionStatus
            )
            lastTimerEvent = .cleared
            lastTimerActionID = activeSession.actionID
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markComplete(_ action: Action) {
        do {
            if let activeSession, activeSession.actionID == action.id {
                try finalize(
                    activeSession: activeSession,
                    actualDuration: elapsedDuration(for: activeSession, now: now()),
                    sessionStatus: .completed,
                    actionStatus: .completed
                )
                lastTimerEvent = .completed
                lastTimerActionID = action.id
                reload()
            } else {
                update(action) { updated in
                    updated.status = .completed
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markInProgress(_ action: Action) {
        update(action) { updated in
            updated.status = .inProgress
        }
    }

    func setBaselineMinutes(id: UUID, minutes: Int) {
        guard let index = preferences.baselineNeeds.firstIndex(where: { $0.id == id }) else { return }
        preferences.baselineNeeds[index].estimateMinutes = max(0, minutes)
        persistPreferences()
    }

    func setBaselineTitle(id: UUID, title: String) {
        guard let index = preferences.baselineNeeds.firstIndex(where: { $0.id == id }) else { return }
        preferences.baselineNeeds[index].title = title
        persistPreferences()
    }

    func setAllocationMode(_ mode: NowAllocationMode) {
        preferences.allocationMode = mode
        persistPreferences()
    }

    func setWeeklyBudgetHours(_ hours: Double) {
        preferences.weeklyBudgetHours = max(0, hours)
        persistPreferences()
    }

    func setWeeklyAllocationTitle(id: UUID, title: String) {
        guard let index = preferences.weeklyAllocations.firstIndex(where: { $0.id == id }) else { return }
        preferences.weeklyAllocations[index].title = title
        persistPreferences()
    }

    func setWeeklyAllocationPercentage(id: UUID, percentage: Double) {
        guard let index = preferences.weeklyAllocations.firstIndex(where: { $0.id == id }) else { return }
        preferences.weeklyAllocations[index].percentage = max(0, percentage)
        preferences.weeklyAllocations[index].weeklyHours = weeklyHours(forPercentage: percentage)
        persistPreferences()
    }

    func setWeeklyAllocationHours(id: UUID, hours: Double) {
        guard let index = preferences.weeklyAllocations.firstIndex(where: { $0.id == id }) else { return }
        preferences.weeklyAllocations[index].weeklyHours = max(0, hours)
        preferences.weeklyAllocations[index].percentage = percentage(forWeeklyHours: hours)
        persistPreferences()
    }

    func setReflectionAM(_ text: String) {
        preferences.reflection.amReflection = text.isEmpty ? nil : text
        persistPreferences()
    }

    func setReflectionPM(_ text: String) {
        preferences.reflection.pmReflection = text.isEmpty ? nil : text
        persistPreferences()
    }

    func setDraftEstimateInputMode(_ mode: NowEstimateInputMode) {
        draftEstimateInputMode = mode
    }

    func setRoutinePlanTimes(id: UUID, startDate: Date, endDate: Date) {
        guard startDate < endDate else {
            errorMessage = "Routine end time must be after the start time."
            return
        }
        guard let index = routinePlans.firstIndex(where: { $0.id == id }) else { return }
        routinePlans[index].startDate = startDate
        routinePlans[index].endDate = endDate
    }

    func setRoutineBlockCategory(planID: UUID, blockID: UUID, category: NowRoutineCategoryKind) {
        guard let planIndex = routinePlans.firstIndex(where: { $0.id == planID }),
              let blockIndex = routinePlans[planIndex].blocks.firstIndex(where: { $0.id == blockID }) else { return }
        routinePlans[planIndex].blocks[blockIndex].category = category
    }

    func setRoutineBlockTitle(planID: UUID, blockID: UUID, title: String) {
        guard let planIndex = routinePlans.firstIndex(where: { $0.id == planID }),
              let blockIndex = routinePlans[planIndex].blocks.firstIndex(where: { $0.id == blockID }) else { return }
        routinePlans[planIndex].blocks[blockIndex].title = title
    }

    func setRoutineBlockDuration(planID: UUID, blockID: UUID, durationMinutes: Int) {
        guard let planIndex = routinePlans.firstIndex(where: { $0.id == planID }),
              let blockIndex = routinePlans[planIndex].blocks.firstIndex(where: { $0.id == blockID }) else { return }
        routinePlans[planIndex].blocks[blockIndex].durationMinutes = max(0, durationMinutes)
    }

    func setRoutineBlockLinkedAction(planID: UUID, blockID: UUID, actionID: UUID?) {
        guard let planIndex = routinePlans.firstIndex(where: { $0.id == planID }),
              let blockIndex = routinePlans[planIndex].blocks.firstIndex(where: { $0.id == blockID }) else { return }
        routinePlans[planIndex].blocks[blockIndex].linkedActionID = actionID
        if actionID != nil {
            routinePlans[planIndex].blocks[blockIndex].linkedProjectID = nil
        }
    }

    func setRoutineBlockLinkedProject(planID: UUID, blockID: UUID, projectID: UUID?) {
        guard let planIndex = routinePlans.firstIndex(where: { $0.id == planID }),
              let blockIndex = routinePlans[planIndex].blocks.firstIndex(where: { $0.id == blockID }) else { return }
        routinePlans[planIndex].blocks[blockIndex].linkedProjectID = projectID
        if projectID != nil {
            routinePlans[planIndex].blocks[blockIndex].linkedActionID = nil
        }
    }

    func moveRoutineBlock(blockID: UUID, to destinationPlanID: UUID) {
        guard let sourcePlanIndex = routinePlans.firstIndex(where: { $0.blocks.contains(where: { $0.id == blockID }) }),
              let blockIndex = routinePlans[sourcePlanIndex].blocks.firstIndex(where: { $0.id == blockID }),
              let destinationPlanIndex = routinePlans.firstIndex(where: { $0.id == destinationPlanID }) else { return }
        let block = routinePlans[sourcePlanIndex].blocks.remove(at: blockIndex)
        routinePlans[destinationPlanIndex].blocks.append(block)
    }

    func plannedMinutes(for action: Action) -> Int {
        Int((action.estimatedDuration ?? SchedulingDefaults.defaultBlockDuration) / 60)
    }

    func actualMinutes(for action: Action, now: Date) -> Int {
        let sessions = sessions.filter { $0.actionID == action.id }
        return actualMinutes(for: sessions, now: now)
    }

    func actualMinutes(for actions: [Action], now: Date) -> Int {
        actions.reduce(0) { $0 + actualMinutes(for: $1, now: now) }
    }

    func todayReflectionSummary(now: Date) -> NowReflectionSummary {
        let todaySessions = sessions.filter { calendar.isDate($0.startDate, inSameDayAs: now) }
        let amCutoff = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: calendar.startOfDay(for: now)) ?? now
        let amSessions = todaySessions.filter { $0.startDate < amCutoff }
        let pmSessions = todaySessions.filter { $0.startDate >= amCutoff }

        return NowReflectionSummary(
            amMinutes: amSessions.reduce(0) { $0 + elapsedMinutes(for: $1, now: now) },
            pmMinutes: pmSessions.reduce(0) { $0 + elapsedMinutes(for: $1, now: now) },
            totalMinutes: todaySessions.reduce(0) { $0 + elapsedMinutes(for: $1, now: now) },
            plannedMinutes: todayPlannedMinutes(now: now)
        )
    }

    func dailyLanes(now: Date) -> [NowLaneSummary] {
        let baselineMinutes = preferences.baselineNeeds.reduce(0) { $0 + $1.estimateMinutes }
        let actualProjectMinutes = actualProjectMinutes(now: now)
        let plannedProjectMinutes = plannedProjectMinutes(now: now)
        let totalPlanned = baselineMinutes + plannedProjectMinutes
        let totalActual = actualProjectMinutes
        let remainingMinutes = max(0, 24 * 60 - totalPlanned)
        let overflowMinutes = max(0, totalPlanned - 24 * 60)

        var lanes: [NowLaneSummary] = [
            NowLaneSummary(
                id: "baseline",
                title: "Baseline life needs",
                subtitle: "Editable estimate, not a truth claim",
                plannedMinutes: baselineMinutes,
                actualMinutes: 0,
                colorToken: .neutral,
                isBaseline: true
            )
        ]

        for allocation in preferences.weeklyAllocations {
            let dailyTarget = dailyTargetMinutes(for: allocation)
            let actual = actualMinutes(forProjectTitle: allocation.title, now: now)
            lanes.append(
                NowLaneSummary(
                    id: allocation.id.uuidString,
                    title: allocation.title,
                    subtitle: allocation.notes,
                    plannedMinutes: dailyTarget,
                    actualMinutes: actual,
                    colorToken: allocation.colorToken,
                    isBaseline: false
                )
            )
        }

        lanes.append(
            NowLaneSummary(
                id: "remaining",
                title: "Unallocated time",
                subtitle: "Left over after baseline and planned work",
                plannedMinutes: remainingMinutes,
                actualMinutes: max(0, totalActual - plannedProjectMinutes),
                colorToken: .sky,
                isBaseline: false
            )
        )

        if overflowMinutes > 0 {
            lanes.append(
                NowLaneSummary(
                    id: "overflow",
                    title: "Over-allocation",
                    subtitle: "The plan exceeds a full day",
                    plannedMinutes: overflowMinutes,
                    actualMinutes: 0,
                    colorToken: .gold,
                    isBaseline: false
                )
            )
        }

        return lanes
    }

    func weeklyAllocationSummary() -> (plannedMinutes: Int, unallocatedMinutes: Int, overflowMinutes: Int) {
        let planned = preferences.weeklyAllocations.reduce(0) { $0 + weeklyMinutes(for: $1) }
        let budget = Int(preferences.weeklyBudgetHours * 60)
        return (
            plannedMinutes: planned,
            unallocatedMinutes: max(0, budget - planned),
            overflowMinutes: max(0, planned - budget)
        )
    }

    func currentSelectionColor(for action: Action) -> NowAllocationColorToken {
        let projectTitle = action.projectID.flatMap { id in projects.first(where: { $0.id == id })?.title } ?? ""
        let lower = projectTitle.lowercased()
        if lower.contains("brand") { return .blue }
        if lower.contains("timebite") { return .green }
        if lower.contains("job") { return .gold }
        return .violet
    }

    func timerStatusText(for action: Action, now: Date) -> String {
        if let activeSession, activeSession.actionID == action.id {
            let planned = max(1, plannedMinutes(for: action))
            let elapsed = elapsedDuration(for: activeSession, now: now)
            return elapsed >= Double(planned) * 60 ? "Timer expired" : "Timer running"
        }

        if lastTimerActionID == action.id, let lastTimerEvent {
            switch lastTimerEvent {
            case .running:
                return "Timer ready"
            case .expired:
                return "Timer expired"
            case .stopped:
                return "Timer stopped"
            case .cleared:
                return "Timer cleared"
            case .completed:
                return "Action completed"
            }
        }

        switch action.status {
        case .inbox, .planned:
            return "Start Action"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    func timerProgress(for action: Action, now: Date) -> Double {
        guard let activeSession, activeSession.actionID == action.id else { return 0 }
        let planned = Double(max(1, plannedMinutes(for: action)))
        return min(1, elapsedDuration(for: activeSession, now: now) / (planned * 60))
    }

    func timerLongPressHint(for action: Action?, now: Date) -> String {
        guard let action else { return "Select an action first." }
        return timerStatusText(for: action, now: now) == "Timer running" ? "Hold to continue timing." : "Press and hold to start timing."
    }

    private func upsertGoal(title: String, categoryID: UUID?) throws -> Goal {
        if let existing = goals.first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
            guard existing.categoryID != categoryID else { return existing }
            var updated = existing
            updated.categoryID = categoryID
            updated.updatedAt = now()
            try repository.save(updated)
            return updated
        }
        let goal = Goal(title: title, categoryID: categoryID, status: .active)
        try repository.save(goal)
        return goal
    }

    private func upsertProject(title: String, goalID: UUID?) throws -> Project {
        if let existing = projects.first(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame && $0.goalID == goalID }) {
            return existing
        }
        let project = Project(goalID: goalID, title: title, status: .active)
        try repository.save(project)
        return project
    }

    private func validatedDraftEstimate() throws -> (duration: TimeInterval?, startDate: Date?, endDate: Date?) {
        switch draftEstimateInputMode {
        case .duration:
            let minutes = max(15, draftEstimateMinutes)
            return (Double(minutes) * 60, nil, nil)
        case .timeRange:
            guard draftEstimateEndDate > draftEstimateStartDate else {
                throw ValidationError.invalidEstimateRange
            }
            return (draftEstimateEndDate.timeIntervalSince(draftEstimateStartDate), draftEstimateStartDate, draftEstimateEndDate)
        }
    }

    private func update(_ action: Action, mutation: (inout Action) -> Void) {
        do {
            var updated = action
            mutation(&updated)
            updated.updatedAt = now()
            try repository.save(updated)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func actionSort(_ lhs: Action, _ rhs: Action) -> Bool {
        let lhsRank = statusRank(lhs.status)
        let rhsRank = statusRank(rhs.status)
        if lhsRank != rhsRank { return lhsRank < rhsRank }
        if lhs.estimatedDuration != rhs.estimatedDuration {
            return (lhs.estimatedDuration ?? .greatestFiniteMagnitude) < (rhs.estimatedDuration ?? .greatestFiniteMagnitude)
        }
        return lhs.createdAt < rhs.createdAt
    }

    private func statusRank(_ status: ActionStatus) -> Int {
        switch status {
        case .inbox: 0
        case .planned: 1
        case .inProgress: 2
        case .completed: 3
        case .cancelled: 4
        }
    }

    private func finalize(
        activeSession: FocusSession,
        actualDuration: TimeInterval,
        sessionStatus: FocusSessionStatus,
        actionStatus: ActionStatus
    ) throws {
        let finishedAt = now()
        var completed = activeSession
        completed.endDate = finishedAt
        completed.actualDuration = max(0, actualDuration)
        completed.status = sessionStatus
        try repository.save(completed)

        if let actionID = activeSession.actionID, let action = actions.first(where: { $0.id == actionID }) {
            var updated = action
            updated.status = actionStatus
            updated.updatedAt = finishedAt
            try repository.save(updated)
        }
    }

    private func actualMinutes(for sessions: [FocusSession], now: Date) -> Int {
        Int(sessions.reduce(0) { $0 + elapsedDuration(for: $1, now: now) } / 60)
    }

    private func elapsedDuration(for session: FocusSession, now: Date) -> TimeInterval {
        switch session.status {
        case .active:
            return max(session.actualDuration, now.timeIntervalSince(session.startDate))
        case .completed, .cancelled:
            return session.actualDuration
        }
    }

    private func elapsedMinutes(for session: FocusSession, now: Date) -> Int {
        Int(elapsedDuration(for: session, now: now) / 60)
    }

    private func plannedMinutes(for actions: [Action]) -> Int {
        actions.reduce(0) { $0 + plannedMinutes(for: $1) }
    }

    private func actualProjectMinutes(now: Date) -> Int {
        preferences.weeklyAllocations.reduce(0) { total, allocation in
            total + actualMinutes(forProjectTitle: allocation.title, now: now)
        }
    }

    private func actualMinutes(forProjectTitle title: String, now: Date) -> Int {
        let lower = title.lowercased()
        let projectActions = actions.filter { action in
            guard let projectID = action.projectID,
                  let projectTitle = projects.first(where: { $0.id == projectID })?.title.lowercased() else { return false }
            return projectTitle == lower
        }
        return actualMinutes(for: projectActions, now: now)
    }

    private func plannedProjectMinutes(now: Date) -> Int {
        preferences.weeklyAllocations.reduce(0) { total, allocation in
            total + dailyTargetMinutes(for: allocation)
        }
    }

    private func todayPlannedMinutes(now: Date) -> Int {
        let baseline = preferences.baselineNeeds.reduce(0) { $0 + $1.estimateMinutes }
        return baseline + plannedProjectMinutes(now: now)
    }

    private func weeklyMinutes(for allocation: WeeklyAllocationPreset) -> Int {
        switch preferences.allocationMode {
        case .percentage:
            return Int((preferences.weeklyBudgetHours * 60) * (allocation.percentage / 100.0))
        case .hours:
            return Int(allocation.weeklyHours * 60)
        }
    }

    private func dailyTargetMinutes(for allocation: WeeklyAllocationPreset) -> Int {
        weeklyMinutes(for: allocation) / 7
    }

    private func weeklyHours(forPercentage percentage: Double) -> Double {
        max(0, preferences.weeklyBudgetHours * (percentage / 100.0))
    }

    private func percentage(forWeeklyHours hours: Double) -> Double {
        guard preferences.weeklyBudgetHours > 0 else { return 0 }
        return max(0, (hours / preferences.weeklyBudgetHours) * 100.0)
    }

    private func persistPreferences() {
        preferencesStore.save(preferences)
    }

    private func makeDefaultRoutinePlans(actions: [Action], projects: [Project], now: Date, calendar: Calendar) -> [NowRoutinePlan] {
        let day = calendar.startOfDay(for: now)
        let morningStart = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: day) ?? day
        let morningEnd = calendar.date(bySettingHour: 11, minute: 30, second: 0, of: day) ?? day.addingTimeInterval(5 * 3600)
        let afternoonStart = morningEnd
        let afternoonEnd = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: day) ?? day.addingTimeInterval(11 * 3600)
        let eveningStart = afternoonEnd
        let eveningEnd = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: day) ?? day.addingTimeInterval(16 * 3600)

        let workAction = actions.first(where: { action in
            let title = action.title.lowercased()
            return title.contains("work") || title.contains("draft") || title.contains("plan")
        })
        let personalAction = actions.first(where: { action in
            let title = action.title.lowercased()
            return title.contains("home") || title.contains("care") || title.contains("rest")
        })
        let project = projects.first

        return [
            NowRoutinePlan(
                period: .morning,
                startDate: morningStart,
                endDate: morningEnd,
                blocks: [
                    NowRoutineBlock(title: "Rest / sleep", category: .rest, durationMinutes: 240, linkedActionID: personalAction?.id),
                    NowRoutineBlock(title: "Fitness / workout", category: .fitness, durationMinutes: 45, linkedActionID: workAction?.id)
                ]
            ),
            NowRoutinePlan(
                period: .afternoon,
                startDate: afternoonStart,
                endDate: afternoonEnd,
                blocks: [
                    NowRoutineBlock(title: "Work / projects", category: .work, durationMinutes: 240, linkedProjectID: project?.id),
                    NowRoutineBlock(title: "Eating", category: .eating, durationMinutes: 90)
                ]
            ),
            NowRoutinePlan(
                period: .evening,
                startDate: eveningStart,
                endDate: eveningEnd,
                blocks: [
                    NowRoutineBlock(title: "Personal / other", category: .personal, durationMinutes: 120),
                    NowRoutineBlock(title: "Rest / sleep", category: .rest, durationMinutes: 180)
                ]
            )
        ]
    }
}

private enum ValidationError: LocalizedError {
    case invalidEstimateRange

    var errorDescription: String? {
        switch self {
        case .invalidEstimateRange:
            return "Estimated end time must be after the start time."
        }
    }
}
