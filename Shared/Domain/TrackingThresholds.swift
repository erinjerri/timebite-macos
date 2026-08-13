import Foundation

enum TrackingThresholds {
    static let achieved = 0.8
    static let partial = 0.01

    static func state(for progress: Double?) -> CalendarProgressState {
        guard let progress else { return .noData }
        if progress >= achieved { return .achieved }
        if progress >= partial { return .partial }
        return .noData
    }
}
