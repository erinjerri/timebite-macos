import SwiftUI

struct PrimaryNavigationBar: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle.uppercased())
                    .font(TimeBiteTypography.font(.caption, weight: .semibold))
                    .tracking(TimeBiteTypography.eyebrowTracking)
                    .foregroundStyle(TimeBitePalette.sky)
                Text(title)
                    .font(TimeBiteTypography.font(.title, weight: .semibold))
                    .foregroundStyle(TimeBitePalette.primaryText(for: colorScheme))
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}
