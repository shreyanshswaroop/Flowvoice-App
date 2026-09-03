import SwiftUI
import AppKit

enum FlowVoiceAppearance: String, CaseIterable, Identifiable {

    case system = "System"
    case light = "Light"
    case dark = "Dark"

    static let storageKey =
        "flowVoiceAppearance"

    var id: String {
        rawValue
    }

    var colorScheme: ColorScheme? {

        switch self {

        case .system:
            nil

        case .light:
            .light

        case .dark:
            .dark
        }
    }

    var nsAppearance: NSAppearance? {

        switch self {

        case .system:
            nil

        case .light:
            NSAppearance(
                named: .aqua
            )

        case .dark:
            NSAppearance(
                named: .darkAqua
            )
        }
    }

    static var stored: FlowVoiceAppearance {

        let rawValue =
            UserDefaults.standard.string(
                forKey: storageKey
            )

        return rawValue
            .flatMap(
                FlowVoiceAppearance.init(
                    rawValue:
                )
            )
            ?? .system
    }

    static func apply(
        _ appearance: FlowVoiceAppearance = .stored
    ) {

        let nsAppearance =
            appearance.nsAppearance

        NSApplication.shared.appearance =
            nil

        NSApplication.shared.windows.forEach { window in

            guard window.flowVoiceCanAdoptAppearance else {
                return
            }

            window.appearance =
                nsAppearance

            window.backgroundColor =
                FlowVoiceTheme.nsWindowBackground
        }

        NotificationCenter.default.post(
            name:
                .flowVoiceAppearanceChanged,
            object:
                appearance
        )
    }
}

// MARK: - Theme

enum FlowVoiceTheme {

    // MARK: Window

    static let windowBackground =
        adaptiveColor(

            light: ThemeColor(
                red: 250,
                green: 249,
                blue: 246
            ),

            dark: ThemeColor(
                red: 18,
                green: 16,
                blue: 14
            )
        )

    // MARK: Main Page

    static let pageBackground =
        adaptiveColor(

            light: ThemeColor(
                red: 250,
                green: 249,
                blue: 246
            ),

            dark: ThemeColor(
                red: 18,
                green: 16,
                blue: 14
            )
        )

    // MARK: Sidebar

    static let sidebarBackground =
        adaptiveColor(

            light: ThemeColor(
                red: 246,
                green: 244,
                blue: 239
            ),

            dark: ThemeColor(
                red: 23,
                green: 21,
                blue: 19
            )
        )

    // MARK: Surfaces

    static let surface =
        adaptiveColor(

            light: ThemeColor(
                red: 250,
                green: 249,
                blue: 246
            ),

            dark: ThemeColor(
                red: 25,
                green: 21,
                blue: 18
            )
        )

    static let elevatedSurface =
        adaptiveColor(

            light: ThemeColor(
                red: 250,
                green: 249,
                blue: 246
            ),

            dark: ThemeColor(
                red: 25,
                green: 21,
                blue: 18
            )
        )

    static let inputSurface =
        adaptiveColor(

            light: ThemeColor(
                red: 250,
                green: 249,
                blue: 246
            ),

            dark: ThemeColor(
                red: 35,
                green: 30,
                blue: 26
            )
        )

    // MARK: Text

    static let primaryText =
        adaptiveColor(

            light: ThemeColor(
                red: 32,
                green: 28,
                blue: 24,
                alpha: 0.90
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.92
            )
        )

    static let secondaryText =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.68
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.68
            )
        )

    static let tertiaryText =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.50
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.50
            )
        )

    static let mutedText =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.36
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.36
            )
        )

    // MARK: Dividers

    static let divider =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.10
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.08
            )
        )

    static let hairline =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.13
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.11
            )
        )

    static let strongHairline =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.20
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.17
            )
        )

    // MARK: Interaction

    static let hoverSurface =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.05
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.06
            )
        )

    static let selectedSurface =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.09
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.10
            )
        )

    static let pressedSurface =
        adaptiveColor(

            light: ThemeColor(
                red: 46,
                green: 40,
                blue: 35,
                alpha: 0.13
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.14
            )
        )

    // MARK: Buttons

    static let accentButton =
        adaptiveColor(

            light: ThemeColor(
                red: 32,
                green: 28,
                blue: 24,
                alpha: 0.92
            ),

            dark: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.92
            )
        )

    static let accentButtonText =
        adaptiveColor(

            light: ThemeColor(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.94
            ),

            dark: ThemeColor(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0.90
            )
        )

    // MARK: NSWindow Background

    static var nsWindowBackground: NSColor {

        adaptiveNSColor(

            light: ThemeColor(
                red: 250,
                green: 249,
                blue: 246
            ),

            dark: ThemeColor(
                red: 18,
                green: 16,
                blue: 14
            )
        )
    }

    // MARK: Helpers

    private static func adaptiveColor(
        light: ThemeColor,
        dark: ThemeColor
    ) -> Color {

        Color(
            nsColor:
                adaptiveNSColor(
                    light: light,
                    dark: dark
                )
        )
    }

    private static func adaptiveNSColor(
        light: ThemeColor,
        dark: ThemeColor
    ) -> NSColor {

        NSColor(
            name: nil
        ) { appearance in

            appearance.flowVoiceUsesDarkMode
                ? dark.nsColor
                : light.nsColor
        }
    }
}

// MARK: - Theme Color

private struct ThemeColor {

    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat = 1
    ) {

        self.red =
            red > 1
            ? red / 255
            : red

        self.green =
            green > 1
            ? green / 255
            : green

        self.blue =
            blue > 1
            ? blue / 255
            : blue

        self.alpha =
            alpha
    }

    var nsColor: NSColor {

        NSColor(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

// MARK: - NSAppearance

private extension NSAppearance {

    var flowVoiceUsesDarkMode: Bool {

        bestMatch(
            from: [
                .darkAqua,
                .aqua
            ]
        ) == .darkAqua
    }
}

// MARK: - NSWindow

private extension NSWindow {

    var flowVoiceCanAdoptAppearance: Bool {

        guard !(self is NSPanel) else {
            return false
        }

        guard canBecomeMain || canBecomeKey else {
            return false
        }

        return level == .normal ||
            level == .floating
    }
}
