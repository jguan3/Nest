import Foundation

/// Mood choices for a low-friction check-in.
enum MoodOption: String, CaseIterable, Identifiable {
    case excited
    case calm
    case okay
    case tired
    case anxious

    var id: String { rawValue }

    /// Short display label for the mood.
    var label: String {
        switch self {
        case .excited: "Excited"
        case .calm: "Calm"
        case .okay: "Okay"
        case .tired: "Tired"
        case .anxious: "Anxious"
        }
    }

    /// Primary SF Symbol name for the mood (Calm also draws a breeze overlay in `MoodSymbolView`).
    var symbol: String {
        switch self {
        case .excited: "sun.max.fill"
        case .calm: "sun.min.fill"
        case .okay: "cloud.sun.fill"
        case .tired: "moon.fill"
        case .anxious: "cloud.bolt.fill"
        }
    }

    /// Gentle response copy shown after selecting this mood.
    var response: String {
        switch self {
        case .excited: "That spark belongs here too. Let it take up space."
        case .calm: "Nice. Let that softness stay a little longer."
        case .okay: "Okay is a valid place to be."
        case .tired: "Rest counts. You don’t have to earn it."
        case .anxious: "You’re safe enough to take one slower breath."
        }
    }
}
