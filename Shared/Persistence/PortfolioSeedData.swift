import Foundation

enum PortfolioSeedData {
    static func makePortfolio() -> Portfolio {
        let cypher = id(1)
        let timeBite = id(2)
        let creative = id(3)
        let faster = id(4)
        let career = id(5)
        let buwaya = id(6)
        let filmSlate = id(7)
        let personal = id(8)

        let taxCompliance = id(401)
        let goodStanding = id(402)
        let expandedProgramming = id(403)
        let buwayaResearch = id(601)
        let buwayaStory = id(602)
        let buwayaStoryboard = id(604)
        let buwayaInteractive = id(606)
        let slateResearch = id(701)
        let slateTreatment = id(702)
        let slateFinancing = id(706)
        let slateProduction = id(707)

        let items = [
            lane(cypher, "Cypher Realities", "Venture studio", .venture, date(2026, 9, 1), date(2029, 12, 31), .high),
            item(101, "Thesis + network foundation", "AI, XR, emerging computing and games", cypher, .phase, .venture, date(2026, 9, 1), date(2026, 12, 31), status: .active, priority: .high, progress: 0.20),
            item(102, "Write investment thesis", "~80% technology allocation", cypher, .project, .venture, date(2026, 9, 8), date(2026, 12, 15), status: .active, priority: .high, progress: 0.12),
            item(103, "Founder + researcher CRM", "Build the relationship system", cypher, .project, .venture, date(2026, 10, 1), date(2027, 3, 31)),
            item(104, "Legal formation", "With counsel", cypher, .project, .venture, date(2027, 1, 4), date(2027, 3, 31), priority: .high, flexibility: .target),
            item(105, "Active operating period", "Founder, researcher and investor meetings", cypher, .phase, .venture, date(2027, 4, 1), date(2027, 11, 30), status: .planned, priority: .high, flexibility: .fixed),
            item(106, "December break", "Protected reset", cypher, .personalConstraint, .venture, date(2027, 12, 1), date(2027, 12, 31), capacity: .low, flexibility: .fixed),
            item(107, "Series 65 study", "Study throughout 2027", cypher, .phase, .venture, date(2027, 1, 1), date(2027, 12, 31), priority: .medium, capacity: .low),
            item(108, "Series 65 complete", "Target by December 31", cypher, .milestone, .venture, date(2027, 12, 31), date(2027, 12, 31), priority: .high),
            item(109, "Capital formation + fundraising", "Develop capital-call and SPV pipeline", cypher, .phase, .venture, date(2028, 1, 1), date(2028, 12, 15), priority: .high, capacity: .high),
            item(110, "Mature operating portfolio", "Sustained venture operations", cypher, .phase, .venture, date(2029, 1, 1), date(2029, 12, 31), status: .idea, priority: .high, capacity: .high),

            lane(timeBite, "Creating Your Reality / TimeBite", "Intention-to-execution platform", .product, date(2026, 9, 1), date(2029, 12, 31), .high),
            item(201, "macOS dogfooding + GANTT", "Goals architecture and daily use", timeBite, .phase, .product, date(2026, 9, 1), date(2026, 11, 15), status: .active, priority: .high, progress: 0.28, capacity: .high),
            item(202, "Beta + user research", "Ship, observe, and learn", timeBite, .phase, .product, date(2026, 11, 1), date(2026, 12, 31), priority: .high, capacity: .high),
            item(203, "Beta release", "End-of-year target", timeBite, .milestone, .product, date(2026, 12, 31), date(2026, 12, 31), priority: .high),
            item(204, "iOS + watchOS", "Companion execution surfaces", timeBite, .phase, .product, date(2027, 2, 1), date(2027, 8, 31), priority: .high, capacity: .high),
            item(205, "Planner integration", "Physical paper planner bridge", timeBite, .project, .product, date(2027, 4, 1), date(2027, 10, 31)),
            item(206, "visionOS", "Spatial planning experiments", timeBite, .project, .product, date(2027, 7, 1), date(2027, 12, 15)),
            item(207, "Pricing + retention experiments", "Acquisition and durable value", timeBite, .phase, .product, date(2027, 8, 1), date(2028, 3, 31), priority: .high),
            item(208, "Cross-platform system", "Mature product foundation", timeBite, .phase, .product, date(2028, 1, 1), date(2028, 12, 31), capacity: .high),
            item(209, "AI glasses experiments", "Meta and Google ecosystems where appropriate", timeBite, .project, .product, date(2028, 5, 1), date(2029, 3, 31), status: .idea),
            item(210, "Mature product platform", "Connected digital and physical ecosystem", timeBite, .phase, .product, date(2029, 1, 1), date(2029, 12, 31), status: .idea, capacity: .high),

            lane(creative, "Tagimata Studios + Mahalohalo", "Creative-business portfolio", .creativeBusiness, date(2026, 9, 1), date(2029, 12, 31), .medium),
            item(301, "Tagimata Studios", "Fashion program", creative, .program, .creativeBusiness, date(2026, 9, 1), date(2029, 12, 31)),
            item(302, "Study + material research", "Fashion design, illustration, draping and CLO3D", id(301), .phase, .creativeBusiness, date(2026, 9, 1), date(2027, 5, 31)),
            item(303, "Prototypes + demand testing", "Learn before scaling", id(301), .phase, .creativeBusiness, date(2027, 4, 1), date(2028, 2, 29)),
            item(304, "Capsules + seasonal releases", "Small intentional collections", id(301), .phase, .creativeBusiness, date(2028, 1, 1), date(2029, 12, 31), status: .idea),
            item(305, "Mahalohalo Cuisine", "Food program", creative, .program, .creativeBusiness, date(2026, 9, 1), date(2029, 12, 31)),
            item(306, "Dessert + menu experiments", "Recipe development and food photography", id(305), .phase, .creativeBusiness, date(2026, 9, 1), date(2027, 5, 31)),
            item(307, "NYC pop-up planning", "Seasonal event development", id(305), .phase, .creativeBusiness, date(2027, 4, 1), date(2028, 3, 31)),
            item(308, "Seasonal NYC events", "Test demand through focused events", id(305), .phase, .creativeBusiness, date(2028, 4, 1), date(2029, 12, 31), status: .idea),
            item(309, "Legal entity formation", "Coordinate with counsel Ruki", creative, .milestone, .creativeBusiness, date(2027, 3, 31), date(2027, 3, 31), priority: .high),

            lane(faster, "FASTER", "Nonprofit", .nonprofit, date(2026, 9, 1), date(2029, 12, 31), .high),
            item(401, "Tax + compliance", "File required taxes", faster, .project, .nonprofit, date(2026, 9, 1), date(2026, 11, 30), status: .active, priority: .high, progress: 0.15),
            item(404, "Rebuild website", "Finish the public foundation", faster, .project, .nonprofit, date(2026, 9, 15), date(2026, 12, 15), priority: .high),
            item(402, "Good standing", "Compliance restored", faster, .milestone, .nonprofit, date(2027, 3, 31), date(2027, 3, 31), priority: .high),
            item(403, "Expanded programming", "Directory, podcast, book and conference", faster, .phase, .nonprofit, date(2027, 4, 1), date(2028, 12, 31), priority: .medium, capacity: .high),

            lane(career, "Career + NYC Transition", "Income, runway and life transition", .career, date(2026, 9, 1), date(2029, 12, 31), .high),
            item(501, "NYC opportunity search", "Primary job search", career, .phase, .career, date(2026, 9, 1), date(2027, 2, 28), status: .active, priority: .high, progress: 0.10, capacity: .high),
            item(502, "Bridge income options", "Temporary, part-time or contract work", career, .project, .career, date(2026, 9, 15), date(2027, 3, 31), priority: .medium, flexibility: .flexible),
            item(503, "NYC life + work rhythm", "Stabilize while developing Cypher", career, .phase, .career, date(2027, 1, 1), date(2027, 12, 31), priority: .high),

            lane(buwaya, "Buwaya", "Transmedia children's IP", .intellectualProperty, date(2026, 10, 1), date(2029, 12, 31), .medium),
            item(601, "IP + research", "World, audience and format research", buwaya, .phase, .intellectualProperty, date(2026, 10, 1), date(2027, 3, 31)),
            item(602, "Story bible", "Narrative foundation", buwaya, .phase, .intellectualProperty, date(2027, 1, 1), date(2027, 6, 30)),
            item(603, "Storybook", "First complete story expression", buwaya, .project, .intellectualProperty, date(2027, 5, 1), date(2027, 12, 31)),
            item(604, "Storyboard + visual prototype", "Translate story into motion and interaction", buwaya, .phase, .intellectualProperty, date(2027, 7, 1), date(2028, 3, 31)),
            item(606, "Interactive/game prototype", "Test the play experience", buwaya, .phase, .intellectualProperty, date(2028, 1, 1), date(2028, 9, 30), capacity: .high),
            item(607, "Game / app", "Production only after prototype validation", buwaya, .project, .intellectualProperty, date(2028, 10, 1), date(2029, 9, 30), status: .idea, capacity: .high),
            item(608, "Children's short film", "Later transmedia expression", buwaya, .project, .intellectualProperty, date(2029, 1, 1), date(2029, 12, 31), status: .idea, capacity: .high),

            lane(filmSlate, "Film / TV / Publishing Slate", "Buwaya, Cooking with Lola, How We Flow", .media, date(2027, 4, 1), date(2029, 12, 31), .medium),
            item(701, "Pre-production research", "April through November", filmSlate, .phase, .media, date(2027, 4, 1), date(2027, 11, 30), priority: .high, flexibility: .fixed),
            item(702, "Treatments", "Define the right format for each property", filmSlate, .phase, .media, date(2027, 7, 1), date(2027, 12, 31)),
            item(703, "Rights + collaborators", "Secure the creative foundation", filmSlate, .phase, .media, date(2027, 9, 1), date(2028, 1, 31)),
            item(704, "Budgets + packages", "Budget, attachments and financing materials", filmSlate, .phase, .media, date(2027, 11, 1), date(2028, 3, 15), priority: .high),
            item(706, "Target financing", "Production remains conditional", filmSlate, .milestone, .media, date(2028, 3, 31), date(2028, 3, 31), priority: .high),
            item(707, "Production window", "Begins only when financing is secured", filmSlate, .phase, .media, date(2028, 5, 1), date(2029, 3, 31), status: .blocked, priority: .high, capacity: .high),
            item(708, "Post + distribution", "Complete and place finished work", filmSlate, .phase, .media, date(2029, 1, 1), date(2029, 12, 31), status: .idea, capacity: .high),

            lane(personal, "Personal / Life", "Constraints and milestones", .personal, date(2026, 9, 1), date(2029, 12, 31), .high),
            item(801, "Fertility / egg-freezing process", "Subject to medical scheduling", personal, .personalConstraint, .personal, date(2026, 9, 1), date(2026, 12, 31), status: .active, priority: .high, flexibility: .flexible),
            item(802, "Planned egg-freezing work complete", "Neutral target, not an overdue task", personal, .milestone, .personal, date(2026, 12, 31), date(2026, 12, 31), priority: .high, flexibility: .flexible),
            item(803, "Mother's Alzheimer's treatment", "Keep scheduling capacity flexible", personal, .personalConstraint, .personal, date(2026, 9, 1), date(2027, 12, 31), status: .active, priority: .high, flexibility: .flexible),
            item(804, "NYC stabilization", "Home and support systems", personal, .phase, .personal, date(2027, 1, 1), date(2027, 9, 30), priority: .high),
            item(805, "Dating re-entry", "Personal milestone", personal, .milestone, .personal, date(2027, 10, 1), date(2027, 10, 1), flexibility: .target)
        ]

        return Portfolio(
            id: id(9_999),
            title: "LifeOS Portfolio",
            subtitle: "Intent → execution → reflection",
            startDate: date(2026, 9, 1),
            endDate: date(2029, 12, 31),
            items: items,
            dependencies: [
                dependency(1, taxCompliance, goodStanding),
                dependency(2, goodStanding, expandedProgramming),
                dependency(3, buwayaResearch, buwayaStory, .startToStart),
                dependency(4, buwayaStory, buwayaStoryboard),
                dependency(5, buwayaStoryboard, buwayaInteractive),
                dependency(6, slateResearch, slateTreatment, .startToStart),
                dependency(7, slateTreatment, slateFinancing),
                dependency(8, slateFinancing, slateProduction)
            ],
            recurringBlocks: [
                RecurringBlock(id: id(901), title: "Friday strategic meetings", subtitle: "Founder, research, health and investor conversations", startDate: date(2026, 9, 4), endDate: date(2029, 12, 28), parentID: cypher, cadence: .weekly, weekday: 6, flexibility: .flexible, notes: "Use TimeBite customer/product work when no outside meeting exists."),
                RecurringBlock(id: id(902), title: "Tagimata weekends", subtitle: "Weekend A", startDate: date(2026, 9, 5), endDate: date(2029, 12, 30), parentID: id(301), cadence: .alternatingWeekends, intervalWeeks: 2),
                RecurringBlock(id: id(903), title: "Mahalohalo weekends", subtitle: "Weekend B", startDate: date(2026, 9, 12), endDate: date(2029, 12, 30), parentID: id(305), cadence: .alternatingWeekends, intervalWeeks: 2),
                RecurringBlock(id: id(904), title: "Series 65 study blocks", subtitle: "Recurring study rhythm", startDate: date(2027, 1, 1), endDate: date(2027, 12, 31), parentID: cypher, cadence: .weekly, flexibility: .target),
                RecurringBlock(id: id(905), title: "Protected / rest weekends", subtitle: "Optional recovery capacity", startDate: date(2026, 9, 1), endDate: date(2029, 12, 31), parentID: personal, cadence: .protectedWeekend, intervalWeeks: 4, flexibility: .flexible)
            ],
            decisionGates: [
                DecisionGate(
                    id: id(950),
                    title: "Leave employment?",
                    date: date(2028, 9, 30),
                    parentID: career,
                    conditions: ["Personal runway", "Venture capital available", "Credible founder/deal pipeline", "Product revenue", "Funded creative slate"],
                    notes: "A decision point, not a requirement to quit. Conditions remain user-editable."
                )
            ]
        )
    }

    private static func lane(
        _ id: UUID,
        _ title: String,
        _ subtitle: String,
        _ type: PortfolioProjectType,
        _ start: Date,
        _ end: Date,
        _ priority: PortfolioPriority
    ) -> PortfolioItem {
        PortfolioItem(id: id, title: title, subtitle: subtitle, startDate: start, endDate: end, status: .active, priority: priority, projectType: type, capacity: .low, kind: .lifeArea)
    }

    private static func item(
        _ value: Int,
        _ title: String,
        _ subtitle: String,
        _ parentID: UUID,
        _ kind: PortfolioItemKind,
        _ type: PortfolioProjectType,
        _ start: Date,
        _ end: Date,
        status: PortfolioItemStatus = .planned,
        priority: PortfolioPriority = .medium,
        progress: Double = 0,
        capacity: PortfolioCapacity = .medium,
        flexibility: PortfolioFlexibility = .target
    ) -> PortfolioItem {
        PortfolioItem(
            id: id(value),
            title: title,
            subtitle: subtitle,
            startDate: start,
            endDate: end,
            status: status,
            priority: priority,
            progress: progress,
            parentID: parentID,
            tags: [type.rawValue],
            notes: subtitle,
            confidence: status == .idea ? 0.35 : 0.70,
            flexibility: flexibility,
            projectType: type,
            capacity: capacity,
            kind: kind
        )
    }

    private static func dependency(
        _ value: Int,
        _ predecessor: UUID,
        _ successor: UUID,
        _ relationship: DependencyRelationship = .finishToStart
    ) -> PortfolioDependency {
        PortfolioDependency(id: id(980 + value), predecessorID: predecessor, successorID: successor, relationship: relationship)
    }

    private static func id(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "A1000000-0000-4000-8000-%012d", value))!
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
