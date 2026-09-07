import SwiftUI

struct TrackCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(TimeBiteTypography.font(.headline, weight: .semibold))
                .tracking(TimeBiteTypography.sectionHeaderTracking)
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(TimeBitePalette.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(TimeBitePalette.border(for: colorScheme)))
    }
}

struct TrackingEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "clock.badge.questionmark",
            description: Text(message)
        )
            .frame(maxWidth: .infinity, minHeight: 180)
    }
}

extension TimeInterval {
    var trackingDuration: String {
        let totalMinutes = Int(self / 60)
        return totalMinutes.formattedTimeBiteDuration
    }
}

extension Int {
    var timeBiteDuration: String {
        formattedTimeBiteDuration
    }
}

private extension Int {
    var formattedTimeBiteDuration: String {
        let hours = self / 60
        let minutes = self % 60
        let hourLabel = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteLabel = minutes == 1 ? "1 minute" : "\(minutes) minutes"

        if hours > 0, minutes == 0 { return hourLabel }
        if hours > 0 { return "\(hourLabel) \(minuteLabel)" }
        return minuteLabel
    }
}

extension Double {
    var trackingPercent: String { "\(Int((min(max(self, 0), 1) * 100).rounded()))%" }
}
