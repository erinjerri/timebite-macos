import Foundation

struct DailyReflectionSummary: Codable, Hashable, Sendable {
    var amReflection: String?
    var pmReflection: String?

    init(amReflection: String? = nil, pmReflection: String? = nil) {
        self.amReflection = amReflection
        self.pmReflection = pmReflection
    }
}
