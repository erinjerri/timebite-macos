import SwiftUI

enum PlanSection: String, CaseIterable, Identifiable {
    case calendar
    case kanban
    case timeline

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct PlanView: View {
    @State private var section: PlanSection = .calendar

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PrimaryNavigationBar(title: "Plan", subtitle: "When am I going to work on this?")
                Spacer()
                Picker("Plan view", selection: $section) {
                    ForEach(PlanSection.allCases) { item in Text(item.title).tag(item) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 330)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider()

            switch section {
            case .calendar:
                TimeBiteCalendarView()
            case .kanban:
                ContentUnavailableView("Kanban is next", systemImage: "rectangle.3.group", description: Text("Calendar will stabilize before another planning interface is added."))
            case .timeline:
                PlanningTimelineView()
            }
        }
    }
}
