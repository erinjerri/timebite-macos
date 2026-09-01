import Foundation

enum DogfoodSeedData {
    static func makeGoals() -> [Goal] {
        let context = makeDateContext()
        let now = Date()

        return [
            Goal(
                id: ids.goal,
                title: "Complete portfolio layout v2 and content audit implementation/merge",
                notes: "Planned work is 7h15m across two days. Docs and porting to the other repos is 2h15m of that - the first thing to slip if day one runs long.",
                startDate: context.today,
                targetDate: context.dayAfterTomorrow,
                status: .active,
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    static func makeMilestones() -> [Milestone] {
        let context = makeDateContext()
        let now = Date()

        return [
            Milestone(
                id: ids.milestone1,
                goalID: ids.goal,
                title: "Code and merge",
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(11 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Milestone(
                id: ids.milestone2,
                goalID: ids.goal,
                title: "Layout v2",
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Milestone(
                id: ids.milestone3,
                goalID: ids.goal,
                title: "Content audit",
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Milestone(
                id: ids.milestone4,
                goalID: ids.goal,
                title: "Assets",
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(12 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Milestone(
                id: ids.milestone5,
                goalID: ids.goal,
                title: "Docs and port",
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    static func makeProjects() -> [Project] {
        let context = makeDateContext()
        let now = Date()

        return [
            Project(
                id: ids.project1,
                goalID: ids.goal,
                milestoneID: ids.milestone1,
                title: "Pull request #32 and dependencies",
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(11 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: ids.project2,
                goalID: ids.goal,
                milestoneID: ids.milestone2,
                title: "Homepage block migration",
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: ids.project3,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                title: "Site copy",
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: ids.project4,
                goalID: ids.goal,
                milestoneID: ids.milestone4,
                title: "Hero artwork",
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(12 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: ids.project5,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                title: "Documentation and downstream repos",
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            ),
            Project(
                id: ids.project6,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                title: "Overflow",
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .active,
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    static func makeActions() -> [Action] {
        let context = makeDateContext()
        let now = Date()

        return [
            Action(
                id: ids.action1,
                goalID: ids.goal,
                milestoneID: ids.milestone1,
                projectID: ids.project1,
                lifeAreaID: LifeArea.work.id,
                title: "Design and content audit",
                estimatedDuration: 0,
                priority: .high,
                startDate: context.yesterday,
                targetDate: context.yesterday,
                status: .completed,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action2,
                goalID: ids.goal,
                milestoneID: ids.milestone1,
                projectID: ids.project1,
                lifeAreaID: LifeArea.work.id,
                title: "Merge PR #32",
                estimatedDuration: 5 * minute,
                priority: .high,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(11 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action3,
                goalID: ids.goal,
                milestoneID: ids.milestone1,
                projectID: ids.project1,
                lifeAreaID: LifeArea.work.id,
                title: "Fix every repo dependency mismatch",
                estimatedDuration: 45 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(11 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action4,
                goalID: ids.goal,
                milestoneID: ids.milestone2,
                projectID: ids.project2,
                lifeAreaID: LifeArea.work.id,
                title: "Delete 5 legacy content blocks",
                estimatedDuration: 15 * minute,
                priority: .high,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action5,
                goalID: ids.goal,
                milestoneID: ids.milestone2,
                projectID: ids.project2,
                lifeAreaID: LifeArea.work.id,
                title: "Add tagPills block after talks",
                estimatedDuration: 10 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action6,
                goalID: ids.goal,
                milestoneID: ids.milestone2,
                projectID: ids.project2,
                lifeAreaID: LifeArea.work.id,
                title: "Reorder blocks and publish",
                estimatedDuration: 10 * minute,
                priority: .high,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action7,
                goalID: ids.goal,
                milestoneID: ids.milestone2,
                projectID: ids.project2,
                lifeAreaID: LifeArea.work.id,
                title: "Capture v2 layout snapshot",
                estimatedDuration: 5 * minute,
                priority: .low,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action8,
                goalID: ids.goal,
                milestoneID: ids.milestone2,
                projectID: ids.project2,
                lifeAreaID: LifeArea.work.id,
                title: "Update v2 layout md after everything lands",
                estimatedDuration: 10 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(15 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action9,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Swap all copy including the stats strip",
                estimatedDuration: 25 * minute,
                priority: .high,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action10,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Speaker page content",
                estimatedDuration: 30 * minute,
                priority: .high,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action11,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Advisory page content",
                estimatedDuration: 20 * minute,
                priority: .high,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action12,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.finance.id,
                title: "CTA advisory rates language",
                estimatedDuration: 15 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action13,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Experience: new TimeBite copy, drop blank project",
                estimatedDuration: 20 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action14,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Add Venture Forward post",
                estimatedDuration: 15 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action15,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.learning.id,
                title: "Add poetry hobby line to bio",
                estimatedDuration: 5 * minute,
                priority: .low,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action16,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Rename nav: Book to Books, Download to App",
                estimatedDuration: 5 * minute,
                priority: .low,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action17,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.work.id,
                title: "Decide on removing follower count",
                estimatedDuration: 5 * minute,
                priority: .low,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action18,
                goalID: ids.goal,
                milestoneID: ids.milestone3,
                projectID: ids.project3,
                lifeAreaID: LifeArea.finance.id,
                title: "Amazon store: fix footer, get storefront URL",
                estimatedDuration: 15 * minute,
                priority: .medium,
                startDate: context.today,
                targetDate: context.today.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action19,
                goalID: ids.goal,
                milestoneID: ids.milestone4,
                projectID: ids.project4,
                lifeAreaID: LifeArea.work.id,
                title: "Re-export hero ribbon at 2560x1440",
                estimatedDuration: 45 * minute,
                priority: .high,
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(12 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action20,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project5,
                lifeAreaID: LifeArea.work.id,
                title: "Update docs for MSFT clarity, add to template",
                estimatedDuration: 30 * minute,
                priority: .medium,
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action21,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project5,
                lifeAreaID: LifeArea.work.id,
                title: "Document store and Stripe pre-order integration",
                estimatedDuration: 45 * minute,
                priority: .medium,
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action22,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project5,
                lifeAreaID: LifeArea.work.id,
                title: "Port docs and changes to cyra-site",
                estimatedDuration: 30 * minute,
                priority: .medium,
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action23,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project5,
                lifeAreaID: LifeArea.work.id,
                title: "Port docs and changes to FASTER-web-26",
                estimatedDuration: 30 * minute,
                priority: .medium,
                startDate: context.tomorrow,
                targetDate: context.tomorrow.addingTimeInterval(18 * hour),
                status: .planned,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action24,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project6,
                lifeAreaID: LifeArea.work.id,
                title: "Optional portrait mobile crop",
                estimatedDuration: 30 * minute,
                priority: .low,
                status: .inbox,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action25,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project6,
                lifeAreaID: LifeArea.work.id,
                title: "Prune 14 stale git worktrees",
                estimatedDuration: 15 * minute,
                priority: .low,
                status: .inbox,
                createdAt: now,
                updatedAt: now
            ),
            Action(
                id: ids.action26,
                goalID: ids.goal,
                milestoneID: ids.milestone5,
                projectID: ids.project6,
                lifeAreaID: LifeArea.work.id,
                title: "Close or finish PR #3",
                estimatedDuration: 10 * minute,
                priority: .low,
                status: .inbox,
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    static func seed(into repository: PlanningRepository) throws {
        let goals = makeGoals()
        guard try repository.goals().contains(where: { $0.id == goals[0].id }) == false else {
            return
        }

        for goal in goals {
            try repository.save(goal)
        }
        for milestone in makeMilestones() {
            try repository.save(milestone)
        }
        for project in makeProjects() {
            try repository.save(project)
        }
        for action in makeActions() {
            try repository.save(action)
        }
    }

    private static let hour: TimeInterval = 3_600
    private static let minute: TimeInterval = 60

    private static func makeDateContext() -> DateContext {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        return DateContext(today: today, tomorrow: tomorrow, dayAfterTomorrow: dayAfterTomorrow, yesterday: yesterday)
    }

    private static let ids = IDs()

    private struct DateContext {
        let today: Date
        let tomorrow: Date
        let dayAfterTomorrow: Date
        let yesterday: Date
    }

    private struct IDs {
        let goal = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

        let milestone1 = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
        let milestone2 = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!
        let milestone3 = UUID(uuidString: "00000000-0000-4000-8000-000000000004")!
        let milestone4 = UUID(uuidString: "00000000-0000-4000-8000-000000000005")!
        let milestone5 = UUID(uuidString: "00000000-0000-4000-8000-000000000006")!

        let project1 = UUID(uuidString: "00000000-0000-4000-8000-000000000007")!
        let project2 = UUID(uuidString: "00000000-0000-4000-8000-000000000008")!
        let project3 = UUID(uuidString: "00000000-0000-4000-8000-000000000009")!
        let project4 = UUID(uuidString: "00000000-0000-4000-8000-000000000010")!
        let project5 = UUID(uuidString: "00000000-0000-4000-8000-000000000011")!
        let project6 = UUID(uuidString: "00000000-0000-4000-8000-000000000012")!

        let action1 = UUID(uuidString: "00000000-0000-4000-8000-000000000013")!
        let action2 = UUID(uuidString: "00000000-0000-4000-8000-000000000014")!
        let action3 = UUID(uuidString: "00000000-0000-4000-8000-000000000015")!
        let action4 = UUID(uuidString: "00000000-0000-4000-8000-000000000016")!
        let action5 = UUID(uuidString: "00000000-0000-4000-8000-000000000017")!
        let action6 = UUID(uuidString: "00000000-0000-4000-8000-000000000018")!
        let action7 = UUID(uuidString: "00000000-0000-4000-8000-000000000019")!
        let action8 = UUID(uuidString: "00000000-0000-4000-8000-000000000020")!
        let action9 = UUID(uuidString: "00000000-0000-4000-8000-000000000021")!
        let action10 = UUID(uuidString: "00000000-0000-4000-8000-000000000022")!
        let action11 = UUID(uuidString: "00000000-0000-4000-8000-000000000023")!
        let action12 = UUID(uuidString: "00000000-0000-4000-8000-000000000024")!
        let action13 = UUID(uuidString: "00000000-0000-4000-8000-000000000025")!
        let action14 = UUID(uuidString: "00000000-0000-4000-8000-000000000026")!
        let action15 = UUID(uuidString: "00000000-0000-4000-8000-000000000027")!
        let action16 = UUID(uuidString: "00000000-0000-4000-8000-000000000028")!
        let action17 = UUID(uuidString: "00000000-0000-4000-8000-000000000029")!
        let action18 = UUID(uuidString: "00000000-0000-4000-8000-000000000030")!
        let action19 = UUID(uuidString: "00000000-0000-4000-8000-000000000031")!
        let action20 = UUID(uuidString: "00000000-0000-4000-8000-000000000032")!
        let action21 = UUID(uuidString: "00000000-0000-4000-8000-000000000033")!
        let action22 = UUID(uuidString: "00000000-0000-4000-8000-000000000034")!
        let action23 = UUID(uuidString: "00000000-0000-4000-8000-000000000035")!
        let action24 = UUID(uuidString: "00000000-0000-4000-8000-000000000036")!
        let action25 = UUID(uuidString: "00000000-0000-4000-8000-000000000037")!
        let action26 = UUID(uuidString: "00000000-0000-4000-8000-000000000038")!
    }
}
