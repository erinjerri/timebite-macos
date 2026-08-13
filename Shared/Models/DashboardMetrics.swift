import Foundation

enum DashboardRange: String, CaseIterable, Identifiable, Sendable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var id: String { rawValue }

    var dayCount: Int {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        case .threeMonths: 90
        case .sixMonths: 180
        case .oneYear: 365
        }
    }
}

struct DashboardSeriesPoint: Identifiable, Hashable, Sendable {
    var id: String { "\(seriesID)-\(date.timeIntervalSinceReferenceDate)" }
    var seriesID: String
    var seriesTitle: String
    var date: Date
    var normalizedValue: Double
}

struct DashboardComponentMetric: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var value: Double
    var detail: String
}

struct DashboardMetrics: Hashable, Sendable {
    var interval: DateInterval
    var series: [DashboardSeriesPoint]
    var components: [DashboardComponentMetric]
    var focusedTime: TimeInterval?
    var completedActions: Int?
    var plannedFocusTime: TimeInterval?
    var actualFocusTime: TimeInterval?
    var hasData: Bool
}
