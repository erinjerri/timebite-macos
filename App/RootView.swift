import SwiftUI

struct RootView: View {
    @StateObject private var navigationState = AppNavigationState()

    var body: some View {
        NavigationSplitView {
            SidebarView(navigationState: navigationState)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
        } detail: {
            destinationView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
    }

    @ViewBuilder
    private var destinationView: some View {
        switch navigationState.selectedDestination {
        case .timeBite(.now):
            NowView()
        case .timeBite(.actions):
            PlaceholderView(title: "Actions", subtitle: "TimeBite", symbol: "checklist")
        case .timeBite(.goals):
            PlaceholderView(title: "Goals", subtitle: "TimeBite", symbol: "target")
        case .timeBite(.plan):
            PlaceholderView(title: "Plan", subtitle: "TimeBite", symbol: "calendar")
        case .timeBite(.track):
            PlaceholderView(title: "Track", subtitle: "TimeBite", symbol: "chart.line.uptrend.xyaxis")
        case .timeBite(.dashboard):
            PlaceholderView(title: "Dashboard", subtitle: "TimeBite", symbol: "rectangle.grid.2x2")
        case .creatingYourReality(.create):
            PlaceholderView(title: "Create", subtitle: "Creating Your Reality", symbol: "sparkles")
        case .creatingYourReality(.discover):
            PlaceholderView(title: "Discover", subtitle: "Creating Your Reality", symbol: "globe")
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
