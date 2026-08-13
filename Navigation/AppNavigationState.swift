import Foundation
import SwiftUI

@MainActor
final class AppNavigationState: ObservableObject {
    @AppStorage("selectedAppSpace") private var storedSpaceRawValue: String = AppSpace.timeBite.rawValue
    @Published var selectedAppSpace: AppSpace {
        didSet {
            storedSpaceRawValue = selectedAppSpace.rawValue
        }
    }
    @Published var selectedTimeBiteDestination: TimeBiteDestination = .now
    @Published var selectedCYRDestination: CYRDestination = .create

    init() {
        selectedAppSpace = AppSpace(rawValue: storedSpaceRawValue) ?? .timeBite
        storedSpaceRawValue = selectedAppSpace.rawValue
    }

    var selectedDestination: AppDestination {
        switch selectedAppSpace {
        case .timeBite:
            return .timeBite(selectedTimeBiteDestination)
        case .creatingYourReality:
            return .creatingYourReality(selectedCYRDestination)
        }
    }

    func select(_ space: AppSpace) {
        selectedAppSpace = space
    }

    func select(_ destination: TimeBiteDestination) {
        selectedAppSpace = .timeBite
        selectedTimeBiteDestination = destination
    }

    func select(_ destination: CYRDestination) {
        selectedAppSpace = .creatingYourReality
        selectedCYRDestination = destination
    }
}

enum AppDestination: Equatable {
    case timeBite(TimeBiteDestination)
    case creatingYourReality(CYRDestination)
}
