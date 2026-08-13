import Foundation

enum TimelineServiceError: Error, Equatable {
    case entityNotFound
    case missingDates
    case invalidDateRange
}

struct TimelineService {
    let repository: any PlanningRepository

    func hierarchy() throws -> [TimelineNode] {
        let goals = try repository.goals()
        let milestones = try repository.milestones()
        let projects = try repository.projects()
        let actions = try repository.actions()

        var includedMilestones = Set<UUID>()
        var includedProjects = Set<UUID>()
        var includedActions = Set<UUID>()

        let goalNodes = goals.map { goal -> TimelineNode in
            let goalMilestones = milestones.filter { $0.goalID == goal.id }.map { milestone -> TimelineNode in
                includedMilestones.insert(milestone.id)
                return milestoneNode(milestone, projects: projects, actions: actions, includedProjects: &includedProjects, includedActions: &includedActions)
            }
            let directProjects = projects.filter { $0.goalID == goal.id && $0.milestoneID == nil }.map { project -> TimelineNode in
                includedProjects.insert(project.id)
                return projectNode(project, actions: actions, includedActions: &includedActions)
            }
            let directActions = actions.filter { $0.goalID == goal.id && $0.milestoneID == nil && $0.projectID == nil }.map {
                includedActions.insert($0.id)
                return actionNode($0)
            }
            return TimelineNode(
                id: .goal(goal.id), title: goal.title, startDate: goal.startDate, targetDate: goal.targetDate,
                children: goalMilestones + directProjects + directActions
            )
        }

        let orphanMilestones = milestones.filter { !includedMilestones.contains($0.id) }.map {
            milestoneNode($0, projects: projects, actions: actions, includedProjects: &includedProjects, includedActions: &includedActions)
        }
        let orphanProjects = projects.filter { !includedProjects.contains($0.id) }.map {
            projectNode($0, actions: actions, includedActions: &includedActions)
        }
        let orphanActions = actions.filter { !includedActions.contains($0.id) }.map(actionNode)
        return goalNodes + orphanMilestones + orphanProjects + orphanActions
    }

    func move(_ id: TimelineEntityID, byDays days: Int, calendar: Calendar = .current) throws {
        try mutate(id) { start, target in
            guard let start, let target else { throw TimelineServiceError.missingDates }
            return (
                calendar.date(byAdding: .day, value: days, to: start) ?? start,
                calendar.date(byAdding: .day, value: days, to: target) ?? target
            )
        }
    }

    func resizeStart(_ id: TimelineEntityID, to date: Date) throws {
        try mutate(id) { _, target in
            guard let target else { throw TimelineServiceError.missingDates }
            guard date <= target else { throw TimelineServiceError.invalidDateRange }
            return (date, target)
        }
    }

    func resizeTarget(_ id: TimelineEntityID, to date: Date) throws {
        try mutate(id) { start, _ in
            guard let start else { throw TimelineServiceError.missingDates }
            guard date >= start else { throw TimelineServiceError.invalidDateRange }
            return (start, date)
        }
    }

    private func milestoneNode(
        _ milestone: Milestone,
        projects: [Project],
        actions: [Action],
        includedProjects: inout Set<UUID>,
        includedActions: inout Set<UUID>
    ) -> TimelineNode {
        let children = projects.filter { $0.milestoneID == milestone.id }.map { project -> TimelineNode in
            includedProjects.insert(project.id)
            return projectNode(project, actions: actions, includedActions: &includedActions)
        } + actions.filter { $0.milestoneID == milestone.id && $0.projectID == nil }.map {
            includedActions.insert($0.id)
            return actionNode($0)
        }
        return TimelineNode(id: .milestone(milestone.id), title: milestone.title, startDate: milestone.startDate, targetDate: milestone.targetDate, children: children)
    }

    private func projectNode(_ project: Project, actions: [Action], includedActions: inout Set<UUID>) -> TimelineNode {
        let children = actions.filter { $0.projectID == project.id }.map {
            includedActions.insert($0.id)
            return actionNode($0)
        }
        return TimelineNode(id: .project(project.id), title: project.title, startDate: project.startDate, targetDate: project.targetDate, children: children)
    }

    private func actionNode(_ action: Action) -> TimelineNode {
        TimelineNode(id: .action(action.id), title: action.title, startDate: action.startDate, targetDate: action.targetDate, children: [])
    }

    private func mutate(
        _ id: TimelineEntityID,
        dates: (Date?, Date?) throws -> (Date, Date)
    ) throws {
        let now = Date()
        switch id {
        case .goal(let value):
            guard var entity = try repository.goals().first(where: { $0.id == value }) else { throw TimelineServiceError.entityNotFound }
            (entity.startDate, entity.targetDate) = try dates(entity.startDate, entity.targetDate)
            entity.updatedAt = now
            try repository.save(entity)
        case .milestone(let value):
            guard var entity = try repository.milestones().first(where: { $0.id == value }) else { throw TimelineServiceError.entityNotFound }
            (entity.startDate, entity.targetDate) = try dates(entity.startDate, entity.targetDate)
            entity.updatedAt = now
            try repository.save(entity)
        case .project(let value):
            guard var entity = try repository.projects().first(where: { $0.id == value }) else { throw TimelineServiceError.entityNotFound }
            (entity.startDate, entity.targetDate) = try dates(entity.startDate, entity.targetDate)
            entity.updatedAt = now
            try repository.save(entity)
        case .action(let value):
            guard var entity = try repository.actions().first(where: { $0.id == value }) else { throw TimelineServiceError.entityNotFound }
            (entity.startDate, entity.targetDate) = try dates(entity.startDate, entity.targetDate)
            entity.updatedAt = now
            try repository.save(entity)
        }
    }
}
