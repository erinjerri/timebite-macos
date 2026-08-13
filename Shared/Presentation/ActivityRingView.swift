import SwiftUI

struct ActivityRingView: View {
    let progress: Double
    let accentColor: Color
    let primaryLabel: String
    let secondaryLabel: String

    init(progress: Double, accentColor: Color = .accentColor, primaryLabel: String, secondaryLabel: String) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.14), style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

            VStack(spacing: 4) {
                Text(primaryLabel)
                    .font(.headline.weight(.semibold))
                Text(secondaryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(primaryLabel)
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

    private var ringLineWidth: CGFloat {
        14
    }
}
