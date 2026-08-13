import SwiftUI

struct ActivityRingView: View {
    let progress: Double
    let accentColor: Color
    let primaryLabel: String
    let secondaryLabel: String
    let lineWidth: CGFloat

    init(
        progress: Double,
        accentColor: Color = .accentColor,
        primaryLabel: String,
        secondaryLabel: String,
        lineWidth: CGFloat = 14
    ) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.14), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

            VStack(spacing: 4) {
                Text(primaryLabel)
                    .font(TimeBiteTypography.font(.headline, weight: .semibold))
                Text(secondaryLabel)
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(primaryLabel)
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

}
