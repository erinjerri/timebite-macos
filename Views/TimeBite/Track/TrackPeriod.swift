import Foundation

enum TrackPeriod: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case annual
    case habits

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
