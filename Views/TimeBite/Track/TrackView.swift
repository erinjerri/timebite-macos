import SwiftUI

struct TrackView: View {
    @StateObject private var model: TrackViewModel

    init(previewData: TrackPreviewData? = nil) {
        _model = StateObject(wrappedValue: TrackViewModel(previewData: previewData))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                PrimaryNavigationBar(title: "Track", subtitle: "What did I actually do?")
                Spacer()
                Picker("Track period", selection: $model.selectedPeriod) {
                    ForEach(TrackPeriod.allCases) { period in Text(period.title).tag(period) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 520)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            Group {
                switch model.selectedPeriod {
                case .daily: DailyTrackView(model: model)
                case .weekly: WeeklyTrackView(model: model)
                case .monthly: MonthlyTrackView(model: model)
                case .annual: AnnualTrackView(model: model)
                case .habits: HabitsTrackView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    TrackView(previewData: .sample())
        .frame(width: 1400, height: 900)
}
