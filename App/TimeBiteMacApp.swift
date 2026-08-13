import SwiftUI

@main
struct TimeBiteMacApp: App {
    init() {
        AppFontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowResizability(.contentSize)
    }
}
