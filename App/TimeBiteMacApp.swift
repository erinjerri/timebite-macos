import SwiftUI

@main
struct TimeBiteMacApp: App {
    init() {
        AppFontRegistrar.registerBundledFonts()

        do {
            try DogfoodSeedData.seed(into: LocalPlanningRepository())
        } catch {
            print("Dogfood seed failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowResizability(.contentSize)
    }
}
