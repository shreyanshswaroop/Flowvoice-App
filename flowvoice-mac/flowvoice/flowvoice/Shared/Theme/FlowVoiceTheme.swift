import SwiftUI
import AppKit

enum FlowVoiceTheme {

    static let windowBackground =
        Color(
            red: 0.050,
            green: 0.053,
            blue: 0.060
        )

    static let pageBackground =
        Color(
            red: 0.060,
            green: 0.064,
            blue: 0.074
        )

    static let sidebarBackground =
        Color(
            red: 0.075,
            green: 0.079,
            blue: 0.090
        )

    static let surface =
        Color(
            red: 0.105,
            green: 0.111,
            blue: 0.126
        )

    static let elevatedSurface =
        Color(
            red: 0.135,
            green: 0.143,
            blue: 0.162
        )

    static let inputSurface =
        Color(
            red: 0.155,
            green: 0.164,
            blue: 0.186
        )

    static let primaryText =
        Color.white.opacity(0.92)

    static let secondaryText =
        Color.white.opacity(0.68)

    static let tertiaryText =
        Color.white.opacity(0.50)

    static let mutedText =
        Color.white.opacity(0.36)

    static let divider =
        Color.white.opacity(0.08)

    static let hairline =
        Color.white.opacity(0.11)

    static let strongHairline =
        Color.white.opacity(0.17)

    static let hoverSurface =
        Color.white.opacity(0.06)

    static let selectedSurface =
        Color.white.opacity(0.10)

    static let pressedSurface =
        Color.white.opacity(0.14)

    static let accentButton =
        Color.white.opacity(0.92)

    static let accentButtonText =
        Color.black.opacity(0.90)

    static var nsWindowBackground: NSColor {
        NSColor(
            red: 0.050,
            green: 0.053,
            blue: 0.060,
            alpha: 1
        )
    }
}
