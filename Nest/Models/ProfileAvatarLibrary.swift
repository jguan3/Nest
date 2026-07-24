import SwiftUI

/// Built-in profile avatar icons users can choose from.
enum ProfileAvatarIcon: String, CaseIterable, Identifiable {
    case person
    case smile
    case heart
    case leaf
    case moon
    case star
    case flower
    case bird

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .person: "person.fill"
        case .smile: "face.smiling.fill"
        case .heart: "heart.fill"
        case .leaf: "leaf.fill"
        case .moon: "moon.fill"
        case .star: "star.fill"
        case .flower: "camera.macro"
        case .bird: "bird.fill"
        }
    }

    var title: String {
        switch self {
        case .person: "Person"
        case .smile: "Smile"
        case .heart: "Heart"
        case .leaf: "Leaf"
        case .moon: "Moon"
        case .star: "Star"
        case .flower: "Flower"
        case .bird: "Bird"
        }
    }
}

/// Soft background colors for profile avatars.
enum ProfileAvatarColor: String, CaseIterable, Identifiable {
    case lilac
    case sky
    case peach
    case mint
    case rose
    case sand
    case dusk
    case teal

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .lilac: Color(red: 0.72, green: 0.58, blue: 1.0)
        case .sky: Color(red: 0.45, green: 0.7, blue: 1.0)
        case .peach: Color(red: 1.0, green: 0.72, blue: 0.55)
        case .mint: Color(red: 0.45, green: 0.85, blue: 0.7)
        case .rose: Color(red: 1.0, green: 0.55, blue: 0.7)
        case .sand: Color(red: 0.9, green: 0.78, blue: 0.55)
        case .dusk: Color(red: 0.55, green: 0.45, blue: 0.85)
        case .teal: Color(red: 0.35, green: 0.7, blue: 0.75)
        }
    }

    var title: String {
        rawValue.capitalized
    }
}

/// AppStorage keys for the built-in avatar library.
enum ProfileAvatarStore {
    static let iconKey = "nest.profile.avatarIcon"
    static let colorKey = "nest.profile.avatarColor"
}
