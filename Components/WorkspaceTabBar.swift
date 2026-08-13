import SwiftUI

struct WorkspaceTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var navigationState: AppNavigationState

    var body: some View {
        VStack(spacing: 12) {
            AppSpaceSwitcher(selectedSpace: Binding(
                get: { navigationState.selectedAppSpace },
                set: { navigationState.select($0) }
            ))
            .frame(width: 360)

            destinationTabs
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(TimeBitePalette.surface(for: colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TimeBitePalette.border(for: colorScheme))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var destinationTabs: some View {
        HStack(spacing: 4) {
            switch navigationState.selectedAppSpace {
            case .timeBite:
                ForEach(TimeBiteDestination.allCases) { destination in
                    tabButton(
                        title: destination.displayTitle,
                        systemImage: destination.symbolName,
                        isSelected: navigationState.selectedTimeBiteDestination == destination
                    ) {
                        navigationState.select(destination)
                    }
                }
            case .creatingYourReality:
                ForEach(CYRDestination.allCases) { destination in
                    tabButton(
                        title: destination.displayTitle,
                        systemImage: destination.symbolName,
                        isSelected: navigationState.selectedCYRDestination == destination
                    ) {
                        navigationState.select(destination)
                    }
                }
            }
        }
        .padding(4)
        .background(
            TimeBitePalette.elevatedSurface(for: colorScheme),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func tabButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(TimeBiteTypography.font(.callout, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(
                isSelected
                    ? TimeBitePalette.primaryText(for: colorScheme)
                    : TimeBitePalette.secondaryText(for: colorScheme)
            )
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? TimeBitePalette.sky.opacity(0.14) : Color.clear)
            )
            .overlay(alignment: .bottom) {
                if isSelected {
                    Capsule()
                        .fill(TimeBitePalette.sky)
                        .frame(width: 22, height: 2)
                        .offset(y: -2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
