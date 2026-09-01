import SwiftUI

struct HealthSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var health = HealthDataService.shared
    @AppStorage("timebite.healthSetup.loadSleep.v1") private var loadSleep = true
    @AppStorage("timebite.healthSetup.loadFitness.v1") private var loadFitness = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Set up your day")
                    .font(TimeBiteTypography.font(.title, weight: .semibold))
                Text("TimeBite can use health data to give your daily plan a more realistic starting point.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $loadSleep) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Load sleep")
                            .font(TimeBiteTypography.font(.headline, weight: .semibold))
                        Text("Pre-allocate 8 hours of sleep until a synced sleep duration is available.")
                            .font(TimeBiteTypography.font(.callout))
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $loadFitness) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Load fitness")
                            .font(TimeBiteTypography.font(.headline, weight: .semibold))
                        Text("Use steps to suggest a fitness goal such as continuing toward 10K today.")
                            .font(TimeBiteTypography.font(.callout))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let message = health.message {
                Text(message)
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(.secondary)
            }

            if let snapshot = health.snapshot {
                Text("Cached snapshot: \(snapshot.stepsToday) steps today · \(sleepSummary(for: snapshot)) sleep")
                    .font(TimeBiteTypography.font(.caption))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Not now") {
                    dismiss()
                }
                Spacer()
                Button("Connect sleep & fitness data") {
                    if loadSleep || loadFitness {
                        health.connectAndRefresh(includeSleep: loadSleep, includeFitness: loadFitness)
                        if health.isAvailable {
                            dismiss()
                        }
                    } else {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(TimeBitePalette.blue)
            }
        }
        .padding(28)
        .frame(width: 520)
    }

    private func sleepSummary(for snapshot: HealthSnapshot) -> String {
        guard let minutes = snapshot.sleepMinutes else { return "--" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(remainingMinutes)m"
    }
}
