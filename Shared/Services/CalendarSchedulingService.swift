import Foundation

enum CalendarSchedulingError: Error, Equatable {
    case actionNotFound
    case blockNotFound
    case invalidSuggestion
}

protocol ExternalCalendarWriting {
    func createEvent(title: String, startDate: Date, endDate: Date, notes: String?) async throws
}

enum CaptureItemKind: String, CaseIterable, Codable, Sendable {
    case task
    case project
    case heading
    case note
}

struct BulkCaptureCandidate: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var sourceText: String
    var title: String
    var kind: CaptureItemKind
    var lifeArea: LifeArea?
    var goalTitle: String?
    var projectLabel: String?
    var priority: ActionPriority?
    var estimatedMinutes: Int?
    var deadline: Date?
    var blockers: [String]
    var context: String?
    var confidence: Double
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        sourceText: String,
        title: String,
        kind: CaptureItemKind = .task,
        lifeArea: LifeArea? = nil,
        goalTitle: String? = nil,
        projectLabel: String? = nil,
        priority: ActionPriority? = nil,
        estimatedMinutes: Int? = nil,
        deadline: Date? = nil,
        blockers: [String] = [],
        context: String? = nil,
        confidence: Double = 0.5,
        isSelected: Bool = true
    ) {
        self.id = id
        self.sourceText = sourceText
        self.title = title
        self.kind = kind
        self.lifeArea = lifeArea
        self.goalTitle = goalTitle
        self.projectLabel = projectLabel
        self.priority = priority
        self.estimatedMinutes = estimatedMinutes
        self.deadline = deadline
        self.blockers = blockers
        self.context = context
        self.confidence = confidence
        self.isSelected = isSelected
    }

    var requiresLifeAreaSelection: Bool { isSelected && lifeArea == nil && kind == .task }
    var requiresGoalSelection: Bool { isSelected && goalTitle == nil && kind == .task }
}

struct BulkCaptureParseResult: Codable, Hashable, Sendable {
    var originalText: String
    var candidates: [BulkCaptureCandidate]
}

struct BulkCaptureParser {
    func parse(_ text: String) -> BulkCaptureParseResult {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
        var candidates: [BulkCaptureCandidate] = []

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let cleaned = stripBulletPrefix(line)
            let kind = inferKind(cleaned)
            let area = inferLifeArea(cleaned)
            let priority = inferPriority(cleaned)
            let minutes = inferEstimate(cleaned, kind: kind)
            let blockers = inferBlockers(cleaned)
            let deadline = inferDeadline(cleaned)
            let context = inferContext(cleaned)
            let confidence = inferenceConfidence(kind: kind, area: area, minutes: minutes)
            candidates.append(
                BulkCaptureCandidate(
                    sourceText: rawLine,
                    title: cleaned,
                    kind: kind,
                    lifeArea: area,
                    goalTitle: inferGoalTitle(cleaned),
                    projectLabel: inferProjectLabel(cleaned),
                    priority: priority,
                    estimatedMinutes: minutes,
                    deadline: deadline,
                    blockers: blockers,
                    context: context,
                    confidence: confidence,
                    isSelected: kind == .task
                )
            )
        }

        return BulkCaptureParseResult(originalText: text, candidates: candidates)
    }

    private func stripBulletPrefix(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let prefixes = ["- ", "* ", "• ", "1. ", "2. ", "3. ", "4. ", "5. "]
        for prefix in prefixes where trimmed.hasPrefix(prefix) {
            return String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        if trimmed.hasSuffix(":") { return String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces) }
        return trimmed
    }

    private func inferKind(_ line: String) -> CaptureItemKind {
        if line.hasSuffix(":") || line.lowercased() == line && line.count < 40 { return .heading }
        if line.lowercased().contains("project") { return .project }
        if line.lowercased().hasPrefix("note ") || line.lowercased().hasPrefix("remember ") { return .note }
        return .task
    }

    private func inferLifeArea(_ line: String) -> LifeArea? {
        let lower = line.lowercased()
        if lower.contains("work") || lower.contains("meeting") || lower.contains("ship") { return .work }
        if lower.contains("home") || lower.contains("kitchen") || lower.contains("clean") { return .home }
        if lower.contains("gym") || lower.contains("run") || lower.contains("sleep") { return .health }
        if lower.contains("errand") || lower.contains("grocery") || lower.contains("pickup") { return .errands }
        if lower.contains("family") || lower.contains("friend") || lower.contains("partner") { return .relationships }
        if lower.contains("budget") || lower.contains("bank") || lower.contains("pay") { return .finance }
        if lower.contains("learn") || lower.contains("study") || lower.contains("read") { return .learning }
        return nil
    }

    private func inferGoalTitle(_ line: String) -> String? {
        line.contains("goal:") ? String(line.split(separator: ":", maxSplits: 1).last ?? "").trimmingCharacters(in: .whitespaces) : nil
    }

    private func inferProjectLabel(_ line: String) -> String? {
        if let range = line.range(of: "project:", options: .caseInsensitive) {
            return line[range.upperBound...].trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private func inferPriority(_ line: String) -> ActionPriority? {
        let lower = line.lowercased()
        if lower.contains("urgent") || lower.contains("asap") { return .high }
        if lower.contains("soon") || lower.contains("important") { return .medium }
        if lower.contains("maybe") || lower.contains("someday") { return .low }
        return nil
    }

    private func inferEstimate(_ line: String, kind: CaptureItemKind) -> Int? {
        guard kind == .task else { return nil }
        let lower = line.lowercased()
        if lower.contains("quick") || lower.contains("reply") || lower.contains("email") { return 15 }
        if lower.contains("draft") || lower.contains("review") || lower.contains("plan") { return 45 }
        if lower.contains("deep") || lower.contains("build") || lower.contains("write") { return 90 }
        return 45
    }

    private func inferBlockers(_ line: String) -> [String] {
        guard line.lowercased().contains("after ") else { return [] }
        return [line]
    }

    private func inferDeadline(_ line: String) -> Date? { nil }

    private func inferContext(_ line: String) -> String? {
        let lower = line.lowercased()
        if lower.contains("home") { return "Home" }
        if lower.contains("errand") { return "Errand" }
        if lower.contains("work") || lower.contains("meeting") { return "Work" }
        return nil
    }

    private func inferenceConfidence(kind: CaptureItemKind, area: LifeArea?, minutes: Int?) -> Double {
        var score = 0.4
        if kind != .task { score -= 0.1 }
        if area != nil { score += 0.25 }
        if minutes != nil { score += 0.15 }
        return min(1, max(0, score))
    }
}

struct EstimateCorrection: Codable, Hashable, Sendable {
    var inputMinutes: Int
    var correctedMinutes: Int
    var createdAt: Date
}

struct EstimateAdjustmentStore: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1
    var schemaVersion: Int = currentSchemaVersion
    var corrections: [EstimateCorrection] = []
}

final class LocalEstimateAdjustmentRepository {
    private static let storeKey = "timebite.estimateAdjustments.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func record(inputMinutes: Int, correctedMinutes: Int) {
        var store = load()
        store.corrections.append(EstimateCorrection(inputMinutes: inputMinutes, correctedMinutes: correctedMinutes, createdAt: Date()))
        defaults.set(try? encoder.encode(store), forKey: Self.storeKey)
    }

    func adjustedEstimate(for minutes: Int) -> Int {
        let corrections = load().corrections.filter { abs($0.inputMinutes - minutes) <= 15 }
        guard !corrections.isEmpty else { return minutes }
        let average = corrections.map(\.correctedMinutes).reduce(0, +) / corrections.count
        return max(15, min(8 * 60, average))
    }

    private func load() -> EstimateAdjustmentStore {
        guard let data = defaults.data(forKey: Self.storeKey),
              let store = try? decoder.decode(EstimateAdjustmentStore.self, from: data),
              store.schemaVersion == EstimateAdjustmentStore.currentSchemaVersion else {
            return EstimateAdjustmentStore()
        }
        return store
    }
}

struct CalendarAvailabilityWindow: Hashable, Sendable {
    var start: Date
    var end: Date
}

struct ScheduledSuggestion: Identifiable, Hashable, Sendable {
    var id: UUID
    var action: Action
    var block: ScheduledBlock
    var reason: String
}

struct CalendarPlanningService {
    let calendar: Calendar
    let availabilityWindow: DateInterval
    let fixedEvents: [ExternalCalendarEvent]

    func openWindows(minimumMinutes: Int = 15) -> [CalendarAvailabilityWindow] {
        let minimum = TimeInterval(minimumMinutes * 60)
        let occupied = fixedEvents
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        var windows: [CalendarAvailabilityWindow] = []
        var cursor = availabilityWindow.start
        for event in occupied {
            if event.startDate.timeIntervalSince(cursor) >= minimum {
                windows.append(.init(start: cursor, end: event.startDate))
            }
            cursor = max(cursor, event.endDate)
        }
        if availabilityWindow.end.timeIntervalSince(cursor) >= minimum {
            windows.append(.init(start: cursor, end: availabilityWindow.end))
        }
        return windows
    }

    func suggest(actions: [Action], estimateRepository: LocalEstimateAdjustmentRepository = .init()) -> [ScheduledSuggestion] {
        let sortedActions = actions
            .filter { !$0.isCompleted && $0.status != .cancelled }
            .sorted { lhs, rhs in
                priorityRank(lhs.priority) < priorityRank(rhs.priority)
            }
        let windows = openWindows()
        var suggestions: [ScheduledSuggestion] = []
        var windowIndex = 0
        var cursor = windows.first?.start

        for action in sortedActions {
            guard var start = cursor else { break }
            let estimated = estimateRepository.adjustedEstimate(for: Int((action.estimatedDuration ?? SchedulingDefaults.defaultBlockDuration) / 60))
            let duration = TimeInterval(min(max(estimated, 15), 90) * 60)
            while windowIndex < windows.count {
                let window = windows[windowIndex]
                if window.end.timeIntervalSince(start) >= duration { break }
                windowIndex += 1
                start = windows[safe: windowIndex]?.start ?? start
                cursor = start
            }
            guard let window = windows[safe: windowIndex] else { break }
            let blockStart = max(start, window.start)
            let blockEnd = blockStart.addingTimeInterval(duration)
            guard blockEnd <= window.end else { continue }
            let block = SchedulingService().schedule(action: action, at: blockStart, duration: duration)
            suggestions.append(
                ScheduledSuggestion(
                    id: UUID(),
                    action: action,
                    block: block,
                    reason: "Fits in an open \(duration.calendarDuration) window before other constraints."
                )
            )
            cursor = blockEnd
            if let currentCursor = cursor, currentCursor >= window.end {
                windowIndex += 1
                cursor = windows[safe: windowIndex]?.start
            }
        }
        return suggestions
    }

    private func priorityRank(_ priority: ActionPriority?) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        case nil: return 3
        }
    }
}

struct CalendarSchedulingService {
    let repository: any PlanningRepository
    private let schedulingService: SchedulingService

    init(
        repository: any PlanningRepository,
        schedulingService: SchedulingService = SchedulingService()
    ) {
        self.repository = repository
        self.schedulingService = schedulingService
    }

    @discardableResult
    func dropAction(id actionID: UUID, at startDate: Date) throws -> ScheduledBlock {
        guard let action = try repository.actions().first(where: { $0.id == actionID }) else {
            throw CalendarSchedulingError.actionNotFound
        }
        let block = schedulingService.schedule(action: action, at: startDate)
        try repository.save(block)
        return block
    }

    @discardableResult
    func moveBlock(id blockID: UUID, to startDate: Date) throws -> ScheduledBlock {
        guard var block = try repository.scheduledBlocks().first(where: { $0.id == blockID }) else {
            throw CalendarSchedulingError.blockNotFound
        }
        block.move(to: startDate)
        try repository.save(block)
        return block
    }

    @discardableResult
    func resizeBlock(id blockID: UUID, to endDate: Date) throws -> ScheduledBlock {
        guard var block = try repository.scheduledBlocks().first(where: { $0.id == blockID }) else {
            throw CalendarSchedulingError.blockNotFound
        }
        block.resize(to: endDate)
        try repository.save(block)
        return block
    }

    @discardableResult
    func updateBlock(_ block: ScheduledBlock) throws -> ScheduledBlock {
        try repository.save(block)
        return block
    }

    @discardableResult
    func completeBlock(id blockID: UUID) throws -> ScheduledBlock {
        guard var block = try repository.scheduledBlocks().first(where: { $0.id == blockID }) else {
            throw CalendarSchedulingError.blockNotFound
        }
        block.complete()
        try repository.save(block)
        return block
    }

    func deleteBlock(id blockID: UUID) throws {
        try repository.deleteScheduledBlock(id: blockID)
    }

    func confirmSuggestion(_ suggestion: ScheduledSuggestion, shouldWriteToCalendar: Bool) throws -> ScheduledBlock {
        guard shouldWriteToCalendar else { throw CalendarSchedulingError.invalidSuggestion }
        try repository.save(suggestion.action)
        try repository.save(suggestion.block)
        return suggestion.block
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
