import SwiftUI

struct GoalsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var health = HealthDataService.shared
    @State private var goals: [Goal] = []
    @State private var categories: [GoalCategory] = []
    @State private var newCategoryTitle = ""
    @State private var isCreatingCategory = false

    private let repository: any PlanningRepository
    private let categoryStore: LocalGoalCategoryStore

    init(repository: (any PlanningRepository)? = nil) {
        self.repository = repository ?? LocalPlanningRepository()
        self.categoryStore = LocalGoalCategoryStore()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PrimaryNavigationBar(title: "Goals", subtitle: "Create categories that fit your life")

                healthCard
                categoriesCard
                goalsCard
            }
            .padding(24)
        }
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.background(for: colorScheme))
        .onAppear(perform: reload)
    }

    private var categoriesCard: some View {
        DashboardCard(title: "Goal categories", systemImage: "square.grid.2x2", tint: TimeBitePalette.violet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Use categories to give each goal a home, such as professional / work / career or fitness.")
                    .font(TimeBiteTypography.font(.callout))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                ForEach(categories) { category in
                    HStack(spacing: 10) {
                        Image(systemName: "tag")
                            .foregroundStyle(TimeBitePalette.violet)
                        Text(category.title)
                        Spacer()
                        Text("\(goals.filter { $0.categoryID == category.id }.count) goals")
                            .font(TimeBiteTypography.font(.caption))
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    }
                    .padding(.vertical, 5)
                }

                if isCreatingCategory {
                    HStack(spacing: 8) {
                        TextField("New category name", text: $newCategoryTitle)
                        Button("Save", action: createCategory)
                            .buttonStyle(.borderedProminent)
                            .disabled(newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    Button {
                        isCreatingCategory = true
                    } label: {
                        Label("Create custom category", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var goalsCard: some View {
        DashboardCard(title: "Your goals", systemImage: "target", tint: TimeBitePalette.teal) {
            if goals.isEmpty {
                ContentUnavailableView("No goals yet", systemImage: "target", description: Text("Create a goal from Now and it will appear here."))
                    .frame(minHeight: 140)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(goals) { goal in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle")
                                .foregroundStyle(TimeBitePalette.teal)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(goal.title)
                                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                                Text(categoryTitle(for: goal) ?? "Uncategorized")
                                    .font(TimeBiteTypography.font(.caption))
                                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var healthCard: some View {
        DashboardCard(title: "Fitness check-in", systemImage: "figure.walk", tint: TimeBitePalette.green) {
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
                    Text(health.snapshot == nil ? "Would you like to keep hitting 10K steps a day?" : "Keep building your 10K-step habit.")
                        .font(TimeBiteTypography.font(.headline, weight: .semibold))
                    Text(health.isLoading ? "Connecting to Health..." : health.message ?? "Connect Health data to personalize fitness goals from your actual activity.")
                        .font(TimeBiteTypography.font(.callout))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    if let snapshot = health.snapshot {
                        HStack(spacing: 10) {
                            Text("Sleep \(sleepSummary(for: snapshot))")
                                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(TimeBitePalette.violet.opacity(0.12), in: Capsule())

                            Text("\(snapshot.stepsToday) steps")
                                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(TimeBitePalette.green.opacity(0.12), in: Capsule())
                        }
                    }
                    Button(health.isAvailable ? "Connect Health data" : "Check for Health data") {
                        health.connectAndRefresh()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(health.isLoading)
                }
            }
        }
    }

    private func reload() {
        goals = (try? repository.goals()) ?? []
        categories = categoryStore.load()
    }

    private func createCategory() {
        let title = newCategoryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if !categories.contains(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
            categories.append(GoalCategory(title: title))
            categoryStore.save(categories)
        }
        newCategoryTitle = ""
        isCreatingCategory = false
    }

    private func categoryTitle(for goal: Goal) -> String? {
        goal.categoryID.flatMap { id in categories.first(where: { $0.id == id })?.title }
    }

    private func sleepSummary(for snapshot: HealthSnapshot) -> String {
        guard let minutes = snapshot.sleepMinutes else { return "--" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(remainingMinutes)m"
    }
}
