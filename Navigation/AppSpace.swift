import Foundation

enum AppSpace: String, CaseIterable, Identifiable, Codable {
    case timeBite
    case creatingYourReality

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .timeBite:
            return "TimeBite"
        case .creatingYourReality:
            return "Creating Your Reality"
        }
    }
}
