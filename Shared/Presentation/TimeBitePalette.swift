import SwiftUI

enum TimeBitePalette {
    // CYRA brand accents from cyra-site's globals.css.
    static let blue = color(hex: 0xA9D6E5)
    static let green = color(hex: 0xB8D8C0)
    static let gold = color(hex: 0xEAD9AB)
    static let pink = color(hex: 0xE8BCC8)
    static let teal = color(hex: 0xA5D5CF)
    static let violet = color(hex: 0xC9BCE8)
    static let sky = blue

    private static func color(hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.06, green: 0.07, blue: 0.11)
            : Color(red: 0.97, green: 0.98, blue: 0.99)
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.09, green: 0.11, blue: 0.17)
            : .white
    }

    static func elevatedSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.16, blue: 0.23)
            : Color(red: 0.94, green: 0.96, blue: 0.99)
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.98, green: 0.98, blue: 0.99)
            : Color(red: 0.11, green: 0.13, blue: 0.17)
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.74, green: 0.76, blue: 0.80)
            : Color(red: 0.49, green: 0.51, blue: 0.56)
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    static func shadow(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? 0.26 : 0.08)
    }

    static func heroGlow(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [violet.opacity(0.14), sky.opacity(0.10), Color.clear]
                : [violet.opacity(0.08), sky.opacity(0.08), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
