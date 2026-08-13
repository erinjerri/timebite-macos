import CoreText
import Foundation

enum AppFontRegistrar {
    private static let leagueSpartanResource = "LeagueSpartan-VariableFont_wght"

    static func registerBundledFonts(in bundle: Bundle = .main) {
        guard let fontURL = bundle.url(forResource: leagueSpartanResource, withExtension: "ttf") else {
            assertionFailure("League Spartan is missing from the app bundle.")
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
