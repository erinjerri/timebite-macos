import Foundation

struct ActiveFocusSession: Codable, Hashable, Sendable {
    var startDate: Date
    var endDate: Date?
    var focusTimeInterval: TimeInterval

    init(startDate: Date, endDate: Date? = nil, focusTimeInterval: TimeInterval) {
        self.startDate = startDate
        self.endDate = endDate
        self.focusTimeInterval = focusTimeInterval
    }
}
