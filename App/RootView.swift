import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var navigationState = AppNavigationState()

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceTabBar(navigationState: navigationState)

            destinationView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(TimeBitePalette.background(for: colorScheme))
        }
        .font(TimeBiteTypography.font(.body))
        .tint(TimeBitePalette.sky)
    }

    @ViewBuilder
    private var destinationView: some View {
        switch navigationState.selectedDestination {
        case .timeBite(.now):
            NowView()
        case .timeBite(.actions):
            PlaceholderView(title: "Actions", subtitle: "TimeBite", symbol: "checklist")
        case .timeBite(.goals):
            GoalsView()
        case .timeBite(.plan):
            PlanView()
        case .timeBite(.track):
            TrackView()
        case .timeBite(.dashboard):
            DashboardView()
        case .creatingYourReality(.create):
            PlaceholderView(title: "Create", subtitle: "Creating Your Reality", symbol: "sparkles")
        case .creatingYourReality(.discover):
            DiscoverView()
        case .creatingYourReality(.journal):
            PlaceholderView(title: "Journal", subtitle: "Creating Your Reality", symbol: "book.pages")
        case .creatingYourReality(.library):
            PlaceholderView(title: "Library", subtitle: "Creating Your Reality", symbol: "books.vertical")
        case .creatingYourReality(.me):
            PlaceholderView(title: "Me", subtitle: "Creating Your Reality", symbol: "person.crop.circle")
        }
    }
}

#Preview {
    RootView()
}
