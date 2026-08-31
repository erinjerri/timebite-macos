import SwiftUI

struct DiscoverView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 16) {
                DiscoverToolCard(
                    title: "Boards",
                    subtitle: "Visual inspiration",
                    icon: AnyView(Image(systemName: "pin.fill")),
                    iconSize: 24,
                    action: {}
                )

                DiscoverToolCard(
                    title: "Ikigai",
                    subtitle: "Find your intersection",
                    icon: AnyView(IkigaiIconView(size: 26, lineWidth: 1.9)),
                    iconSize: 26,
                    action: {}
                )
            }

            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
        .background(TimeBitePalette.background(for: colorScheme))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DISCOVER")
                .font(TimeBiteTypography.font(.caption, weight: .semibold))
                .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
            Text("Tools for exploring and assembling ideas")
                .font(TimeBiteTypography.font(.largeTitle, weight: .semibold))
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16, alignment: .topLeading)]
    }
}

private struct DiscoverToolCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let icon: AnyView
    let iconSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                icon
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(TimeBiteTypography.font(.title3, weight: .semibold))
                    Text(subtitle)
                        .font(TimeBiteTypography.font(.callout))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .padding(18)
            .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TimeBitePalette.border(for: colorScheme), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DiscoverView()
}
