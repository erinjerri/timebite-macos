import SwiftUI

struct PlaceholderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(TimeBitePalette.sky)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle.uppercased())
                        .font(TimeBiteTypography.font(.caption, weight: .semibold))
                        .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    Text(title)
                        .font(TimeBiteTypography.font(.largeTitle, weight: .semibold))
                }
            }

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TimeBitePalette.surface(for: colorScheme))
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Placeholder surface")
                            .font(TimeBiteTypography.font(.headline))
                        Text("This destination is ready for the next implementation step.")
                            .foregroundStyle(TimeBitePalette.secondaryText(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(24)
                )
                .frame(minHeight: 420)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
    }
}

#Preview {
    PlaceholderView(title: "Goals", subtitle: "TimeBite", symbol: "target")
}
