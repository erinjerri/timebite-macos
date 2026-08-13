import Combine
import Foundation
import SwiftUI

@MainActor
final class AppNavigationState: ObservableObject {
    private let selectedAppSpaceKey = "selectedAppSpace"
    private let defaults: UserDefaults

    @Published var selectedAppSpace: AppSpace {
        didSet {
            defaults.set(selectedAppSpace.rawValue, forKey: selectedAppSpaceKey)
        }
    }
    @Published var selectedTimeBiteDestination: TimeBiteDestination = .now
    @Published var selectedCYRDestination: CYRDestination = .create

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedAppSpace = AppSpace(rawValue: defaults.string(forKey: selectedAppSpaceKey) ?? AppSpace.timeBite.rawValue) ?? .timeBite
        defaults.set(selectedAppSpace.rawValue, forKey: selectedAppSpaceKey)
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
