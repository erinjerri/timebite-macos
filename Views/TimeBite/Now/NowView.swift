import SwiftUI

struct NowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var actionFieldIsFocused: Bool
    @State private var draftedAction = ""
    @State private var captureMode: ActionCaptureMode = .keyboard
    @State private var isLiveActivityRunning = false
    @State private var actions = NowPreviewModel.sample.todayActions

    private let previewModel = NowPreviewModel.sample

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PrimaryNavigationBar(title: "Now", subtitle: "TimeBite")

                LiveActivityWorkspace(
                    progress: previewModel.liveProgress,
                    draftedAction: $draftedAction,
                    captureMode: $captureMode,
                    isRunning: $isLiveActivityRunning,
                    actionFieldIsFocused: $actionFieldIsFocused,
                    onSubmit: submitAction
                )

                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 16) {
                    DailyActionsCard(actions: $actions)
                    ActiveTaskCard(taskTitle: previewModel.activeTaskTitle, linkedGoal: previewModel.linkedGoalTitle)
                    SummaryRingCard(
                        title: "AM Summary",
                        text: previewModel.amSummary,
                        progress: previewModel.amProgress,
                        tint: TimeBitePalette.gold,
                        label: "AM"
                    )
                    SummaryRingCard(
                        title: "PM Summary",
                        text: previewModel.pmSummary,
                        progress: previewModel.pmProgress,
                        tint: TimeBitePalette.violet,
                        label: "PM"
                    )
                    SummaryRingCard(
                        title: "Daily Progress",
                        text: "You are making steady progress toward the day's intent.",
                        progress: previewModel.dailyProgress,
                        tint: TimeBitePalette.sky,
                        label: "Today"
                    )
                    LinkedGoalCard(goalTitle: previewModel.linkedGoalTitle, goalSubtitle: previewModel.linkedGoalSubtitle)
                }
            }
            .padding(24)
        }
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.background(for: colorScheme))
        .navigationTitle("Now")
        .toolbarTitleDisplayMode(.automatic)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 290, maximum: 440), spacing: 16)]
    }

    private func submitAction() {
        let title = draftedAction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        actions.append(TodayAction(title: title))
        draftedAction = ""
        captureMode = .keyboard
        actionFieldIsFocused = true
    }
}

private enum ActionCaptureMode: String, CaseIterable, Identifiable {
    case keyboard
    case speech
    case vision

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .keyboard: "keyboard"
        case .speech: "waveform"
        case .vision: "viewfinder"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .keyboard: "Type action"
        case .speech: "Capture action with speech"
        case .vision: "Capture action with computer vision"
        }
    }
}

private struct TodayAction: Identifiable {
    let id = UUID()
    let title: String
    var isComplete = false
}

private struct NowPreviewModel {
    let liveProgress: Double
    let amProgress: Double
    let pmProgress: Double
    let dailyProgress: Double
    let activeTaskTitle: String
    let linkedGoalTitle: String
    let linkedGoalSubtitle: String
    let todayActions: [TodayAction]
    let amSummary: String
    let pmSummary: String

    static let sample = NowPreviewModel(
        liveProgress: 0.64,
        amProgress: 0.82,
        pmProgress: 0.46,
        dailyProgress: 0.64,
        activeTaskTitle: "Draft the next product brief",
        linkedGoalTitle: "Ship the macOS shell",
        linkedGoalSubtitle: "Support a clean workspace-first app",
        todayActions: [
            TodayAction(title: "Review navigation hierarchy", isComplete: true),
            TodayAction(title: "Confirm persistent space switching"),
            TodayAction(title: "Outline next shared model extraction")
        ],
        amSummary: "The morning intention is clear and the first focus block is already underway.",
        pmSummary: "Capture what moved forward, what changed, and what should carry into tomorrow."
    )
}

private struct LiveActivityWorkspace: View {
    @Environment(\.colorScheme) private var colorScheme
    let progress: Double
    @Binding var draftedAction: String
    @Binding var captureMode: ActionCaptureMode
    @Binding var isRunning: Bool
    var actionFieldIsFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            VStack(spacing: 16) {
                ActivityRingView(
                    progress: progress,
                        accentColor: TimeBitePalette.teal,
                    primaryLabel: "\(Int(progress * 100))%",
                    secondaryLabel: isRunning ? "Live" : "Ready",
                    lineWidth: 17
                )
                .frame(width: 164, height: 164)

                Button {
                    isRunning.toggle()
                } label: {
                    Label(isRunning ? "Pause focus" : "Start focus", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(TimeBiteTypography.font(.callout, weight: .semibold))
                        .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.11))
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(TimeBitePalette.teal, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 200)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("LIVE ACTIVITY")
                        .font(TimeBiteTypography.font(.caption2, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(TimeBitePalette.teal)
                    Text("What are you moving forward now?")
                        .font(TimeBiteTypography.font(.title2, weight: .semibold))
                }

                HStack(spacing: 10) {
                    TextField("Create an action", text: $draftedAction)
                        .textFieldStyle(.plain)
                        .font(TimeBiteTypography.font(.body, weight: .medium))
                        .focused(actionFieldIsFocused)
                        .onSubmit(onSubmit)

                    ForEach(ActionCaptureMode.allCases) { mode in
                        Button {
                            captureMode = mode
                            if mode == .keyboard {
                                actionFieldIsFocused.wrappedValue = true
                            }
                        } label: {
                            Image(systemName: mode.symbolName)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(captureMode == mode ? TimeBitePalette.sky : TimeBitePalette.secondaryText(for: colorScheme))
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(captureMode == mode ? TimeBitePalette.sky.opacity(0.13) : Color.clear)
                        )
                        .help(mode.accessibilityLabel)
                        .accessibilityLabel(mode.accessibilityLabel)
                    }

                    Button(action: onSubmit) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.11))
                            .frame(width: 34, height: 34)
                            .background(TimeBitePalette.teal, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(draftedAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(draftedAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                    .help("Add action")
                    .accessibilityLabel("Add action")
                }
                .padding(.leading, 14)
                .padding(.trailing, 8)
                .frame(height: 50)
                .background(TimeBitePalette.elevatedSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
                )

                Text(captureHint)
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))

                HStack(spacing: 18) {
                    metric(value: "38m", label: "focused")
                    metric(value: "22m", label: "remaining")
                    metric(value: "1", label: "linked goal")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .leading)
        .background {
            ZStack {
                TimeBitePalette.surface(for: colorScheme)
                TimeBitePalette.heroGlow(for: colorScheme)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: TimeBitePalette.shadow(for: colorScheme), radius: 18, y: 8)
    }

    private var captureHint: String {
        switch captureMode {
        case .keyboard: "Type an action, then press Return or submit."
        case .speech: "Speech-to-text capture is selected and ready for service integration."
        case .vision: "Computer-vision capture is selected and ready for service integration."
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(TimeBiteTypography.font(.headline, weight: .semibold))
            Text(label)
                .font(TimeBiteTypography.font(.caption2))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
        }
    }
}

private struct ActiveTaskCard: View {
    let taskTitle: String
    let linkedGoal: String

    var body: some View {
        DashboardCard(title: "Current / Active Task", systemImage: "bolt.fill", tint: TimeBitePalette.sky) {
            Text(taskTitle)
                .font(TimeBiteTypography.font(.title3, weight: .semibold))
            Text("Linked to \(linkedGoal)")
                .foregroundStyle(.secondary)
        }
    }
}

private struct DailyActionsCard: View {
    @Binding var actions: [TodayAction]

    var body: some View {
        DashboardCard(title: "Today's Actions", systemImage: "checklist", tint: TimeBitePalette.sky) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach($actions) { $action in
                    Button {
                        action.isComplete.toggle()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: action.isComplete ? "checkmark.square.fill" : "square")
                        .foregroundStyle(action.isComplete ? TimeBitePalette.sky : .secondary)
                            Text(action.title)
                                .strikethrough(action.isComplete, color: .secondary)
                                .foregroundStyle(action.isComplete ? .secondary : .primary)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(action.isComplete ? "Mark \(action.title) incomplete" : "Mark \(action.title) complete")
                }
            }
            .font(TimeBiteTypography.font(.callout))
        }
    }
}

private struct SummaryRingCard: View {
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
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct LinkedGoalCard: View {
    let goalTitle: String
    let goalSubtitle: String

    var body: some View {
        DashboardCard(title: "Linked Goal", systemImage: "target", tint: TimeBitePalette.violet) {
            Text(goalTitle)
                .font(TimeBiteTypography.font(.title3, weight: .semibold))
            Text(goalSubtitle)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DashboardCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder var content: Content

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
