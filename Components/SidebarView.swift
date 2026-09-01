import SwiftUI

struct SidebarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var navigationState: AppNavigationState

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    switch navigationState.selectedAppSpace {
                    case .timeBite:
                        primarySection(title: "TimeBite", items: TimeBiteDestination.allCases) { destination in
                            navigationState.select(destination)
                        } selected: {
                            if case let .timeBite(destination) = navigationState.selectedDestination {
                                return destination.id
                            }
                            return TimeBiteDestination.now.id
                        }
                    case .creatingYourReality:
                        primarySection(title: "Creating Your Reality", items: CYRDestination.allCases) { destination in
                            navigationState.select(destination)
                        } selected: {
                            if case let .creatingYourReality(destination) = navigationState.selectedDestination {
                                return destination.id
                            }
                            return CYRDestination.create.id
                        }
                    }
                }
                .padding(16)
            }

            Divider()
        }
        .frame(minHeight: 520, alignment: .top)
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.surface(for: colorScheme))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TimeBite")
                .font(TimeBiteTypography.font(.headline, weight: .semibold))
            AppSpaceSwitcher(
                selectedSpace: navigationState.selectedAppSpace,
                onSelect: { navigationState.select($0) }
            )
        }
    }

    private func primarySection<Item: Identifiable & CaseIterable & CustomStringConvertible>(
        title: String,
        items: Item.AllCases,
        action: @escaping (Item) -> Void,
        selected: @escaping () -> Item.ID
    ) -> some View where Item.AllCases: RandomAccessCollection, Item.AllCases.Element == Item {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .tracking(TimeBiteTypography.eyebrowTracking)
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                .padding(.horizontal, 8)

            ForEach(items) { item in
                let isSelected = selected() == item.id
                Button {
                    action(item)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: symbolName(for: item))
                            .frame(width: 20)
                        Text(item.description)
                        Spacer(minLength: 0)
                    }
                    .font(TimeBiteTypography.font(size: 13.5, weight: isSelected ? .semibold : .regular))
                    .padding(.vertical, 9)
                    .padding(.horizontal, 12)
                    .background(isSelected ? TimeBitePalette.sky.opacity(0.13) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(isSelected ? TimeBitePalette.primaryText(for: colorScheme) : TimeBitePalette.secondaryText(for: colorScheme))
            }
        }
    }

    private func symbolName(for item: some CustomStringConvertible) -> String {
        switch item.description {
        case "Now": return "dot.radiowaves.left.and.right"
        case "Actions": return "checklist"
        case "Goals": return "target"
        case "Plan": return "calendar"
        case "Track": return "chart.line.uptrend.xyaxis"
        case "Dashboard": return "rectangle.grid.2x2"
        case "Create": return "sparkles"
        case "Discover": return "globe"
        case "Journal": return "book.pages"
        case "Library": return "books.vertical"
        case "Me": return "person.crop.circle"
        default: return "circle"
        }
    }
}
