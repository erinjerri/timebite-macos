import Foundation

enum TrackPeriod: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
