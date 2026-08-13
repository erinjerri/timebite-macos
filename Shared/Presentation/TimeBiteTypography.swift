import SwiftUI

enum TimeBiteTypography {
    static let familyName = "League Spartan"

    static func font(
        _ style: Font.TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        Font.custom(
            familyName,
            size: baseSize(for: style),
            relativeTo: style
        )
        .weight(weight)
    }

    static func font(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        Font.custom(familyName, size: size, relativeTo: style)
            .weight(weight)
    }

    private static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 13
        case .subheadline: 12
        case .body: 13
        case .callout: 12
        case .footnote: 11
        case .caption: 11
        case .caption2: 10
        @unknown default: 13
        }
    }
}
