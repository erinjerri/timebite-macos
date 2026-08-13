import SwiftUI

struct NowView: View {
    private let previewModel = NowPreviewModel.sample

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PrimaryNavigationBar(title: "Now", subtitle: "TimeBite")

                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 16) {
                    LiveActivityRingCard(progress: previewModel.dailyProgress)
                    ActiveTaskCard(taskTitle: previewModel.activeTaskTitle, linkedGoal: previewModel.linkedGoalTitle)
                    DailyActionsCard(actions: previewModel.todayActions)
                    SummaryCard(title: "AM Summary", text: previewModel.amSummary, systemImage: "sunrise")
                    SummaryCard(title: "PM Summary", text: previewModel.pmSummary, systemImage: "sunset")
                    ProgressCard(progress: previewModel.dailyProgress)
                }

                LinkedGoalCard(goalTitle: previewModel.linkedGoalTitle, goalSubtitle: previewModel.linkedGoalSubtitle)
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Now")
        .toolbarTitleDisplayMode(.automatic)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 280, maximum: 420), spacing: 16),
            GridItem(.flexible(minimum: 280, maximum: 420), spacing: 16)
        ]
    }
}

private struct NowPreviewModel {
    let dailyProgress: Double
    let activeTaskTitle: String
    let linkedGoalTitle: String
    let linkedGoalSubtitle: String
    let todayActions: [String]
    let amSummary: String
    let pmSummary: String

    static let sample = NowPreviewModel(
        dailyProgress: 0.64,
        activeTaskTitle: "Draft the next product brief",
        linkedGoalTitle: "Ship the macOS shell",
        linkedGoalSubtitle: "Support a clean workspace-first app",
        todayActions: [
            "Review navigation hierarchy",
            "Confirm persistent space switching",
            "Outline next shared model extraction"
        ],
        amSummary: "This morning is about reducing uncertainty and getting the shell into a state where the rest of the app can land cleanly.",
        pmSummary: "This afternoon should focus on polish, spacing, and validating that the layout still feels comfortable when the window is resized."
    )
}

private struct LiveActivityRingCard: View {
    let progress: Double

    var body: some View {
        CardContainer(title: "Live Activity Ring", systemImage: "circle.dotted.circle") {
            ProgressView(value: progress) {
                Text("Today")
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
            }
            .progressViewStyle(.linear)

            Text("Track the current day without overwhelming the workspace.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ActiveTaskCard: View {
    let taskTitle: String
    let linkedGoal: String

    var body: some View {
        CardContainer(title: "Current / Active Task", systemImage: "bolt.circle") {
            Text(taskTitle)
                .font(.title3.weight(.semibold))

            Text("Linked goal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Text(linkedGoal)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DailyActionsCard: View {
    let actions: [String]

    var body: some View {
        CardContainer(title: "Today's Actions", systemImage: "checklist") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(actions, id: \.self) { action in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle")
                            .font(.system(size: 8, weight: .semibold))
                            .padding(.top, 6)
                        Text(action)
                    }
                }
            }
            .font(.callout)
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let text: String
    let systemImage: String

    var body: some View {
        CardContainer(title: title, systemImage: systemImage) {
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProgressCard: View {
    let progress: Double

    var body: some View {
        CardContainer(title: "Daily Progress", systemImage: "chart.bar.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: progress)
                Text("You are making steady progress toward the day's intent.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct LinkedGoalCard: View {
    let goalTitle: String
    let goalSubtitle: String

    var body: some View {
        CardContainer(title: "Linked Goal", systemImage: "target") {
            Text(goalTitle)
                .font(.title3.weight(.semibold))
            Text(goalSubtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CardContainer<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer(minLength: 0)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
