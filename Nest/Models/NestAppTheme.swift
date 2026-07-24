import SwiftUI

/// User-selectable app color themes for Nest.
enum NestAppTheme: String, CaseIterable, Identifiable {
    case duskPurple
    case oceanBlue
    case forestMist
    case warmRose
    case slateInk

    static let storageKey = "nest.colorTheme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .duskPurple: "Dusk Purple"
        case .oceanBlue: "Ocean Blue"
        case .forestMist: "Forest Mist"
        case .warmRose: "Warm Rose"
        case .slateInk: "Slate Ink"
        }
    }

    var subtitle: String {
        switch self {
        case .duskPurple: "The original Nest glow"
        case .oceanBlue: "Cool water and sky"
        case .forestMist: "Soft greens and moss"
        case .warmRose: "Gentle blush light"
        case .slateInk: "Quiet charcoal calm"
        }
    }

    /// Resolves the saved theme, falling back to dusk purple.
    static var current: NestAppTheme {
        NestAppTheme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .duskPurple
    }

    var backgroundColors: [Color] {
        switch self {
        case .duskPurple:
            [
                Color(red: 0.16, green: 0.10, blue: 0.30),
                Color(red: 0.22, green: 0.14, blue: 0.40),
                Color(red: 0.12, green: 0.16, blue: 0.34)
            ]
        case .oceanBlue:
            [
                Color(red: 0.08, green: 0.14, blue: 0.28),
                Color(red: 0.10, green: 0.22, blue: 0.40),
                Color(red: 0.06, green: 0.18, blue: 0.32)
            ]
        case .forestMist:
            [
                Color(red: 0.08, green: 0.16, blue: 0.14),
                Color(red: 0.12, green: 0.24, blue: 0.20),
                Color(red: 0.10, green: 0.18, blue: 0.22)
            ]
        case .warmRose:
            [
                Color(red: 0.22, green: 0.10, blue: 0.18),
                Color(red: 0.30, green: 0.12, blue: 0.22),
                Color(red: 0.16, green: 0.10, blue: 0.20)
            ]
        case .slateInk:
            [
                Color(red: 0.10, green: 0.11, blue: 0.16),
                Color(red: 0.14, green: 0.15, blue: 0.22),
                Color(red: 0.08, green: 0.09, blue: 0.14)
            ]
        }
    }

    var accentColors: [Color] {
        switch self {
        case .duskPurple:
            [Color(red: 0.45, green: 0.55, blue: 1.0), Color(red: 0.65, green: 0.45, blue: 0.98)]
        case .oceanBlue:
            [Color(red: 0.30, green: 0.65, blue: 1.0), Color(red: 0.25, green: 0.85, blue: 0.90)]
        case .forestMist:
            [Color(red: 0.35, green: 0.80, blue: 0.60), Color(red: 0.45, green: 0.70, blue: 0.45)]
        case .warmRose:
            [Color(red: 1.0, green: 0.55, blue: 0.70), Color(red: 0.95, green: 0.45, blue: 0.55)]
        case .slateInk:
            [Color(red: 0.55, green: 0.65, blue: 0.85), Color(red: 0.70, green: 0.75, blue: 0.90)]
        }
    }

    var glowPrimary: Color {
        switch self {
        case .duskPurple: Color.purple
        case .oceanBlue: Color.blue
        case .forestMist: Color.green
        case .warmRose: Color.pink
        case .slateInk: Color.gray
        }
    }

    var glowSecondary: Color {
        switch self {
        case .duskPurple: Color.blue
        case .oceanBlue: Color.cyan
        case .forestMist: Color.mint
        case .warmRose: Color.orange
        case .slateInk: Color.blue
        }
    }

    var glowTertiary: Color {
        switch self {
        case .duskPurple: Color(red: 0.85, green: 0.45, blue: 0.75)
        case .oceanBlue: Color(red: 0.35, green: 0.75, blue: 0.95)
        case .forestMist: Color(red: 0.55, green: 0.85, blue: 0.55)
        case .warmRose: Color(red: 1.0, green: 0.65, blue: 0.55)
        case .slateInk: Color(red: 0.65, green: 0.70, blue: 0.85)
        }
    }

    var tabTint: Color {
        accentColors.first ?? Color(red: 0.72, green: 0.55, blue: 1.0)
    }

    var swatch: Color {
        accentColors.last ?? tabTint
    }
}

/// Keys for Personal settings toggles.
enum NestSettingsKeys {
    static let soundsEnabled = "nest.settings.soundsEnabled"
    static let hapticsEnabled = "nest.settings.hapticsEnabled"
}
