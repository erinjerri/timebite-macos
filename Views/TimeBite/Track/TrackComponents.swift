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
        ContentUnavailableView(title, systemImage: "clock.badge.questionmark", description: Text(message))
            .frame(maxWidth: .infinity, minHeight: 180)
    }
}

extension TimeInterval {
    var trackingDuration: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0, minutes == 0 { return "\(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

extension Int {
    var timeBiteDuration: String {
        let hours = self / 60
        let minutes = self % 60
        if hours > 0, minutes == 0 { return "\(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

extension Double {
    var trackingPercent: String { "\(Int((min(max(self, 0), 1) * 100).rounded()))%" }
}
