import Foundation

/// A feature that can be highlighted by the onboarding spotlight.
enum OnboardingHighlight: String, Hashable {
    case moodCheckIn
    case voiceReflection
    case wellnessTools
    case history

    /// The app tab containing this feature.
    var tabIndex: Int {
        switch self {
        case .moodCheckIn:
            return 0
        case .voiceReflection:
            return 1
        case .wellnessTools:
            return 2
        case .history:
            return 3
        }
    }
}

/// A preferred location for the information card relative to its spotlight.
enum OnboardingTooltipPosition {
    case above
    case below
    case centered
}

/// One page in the first-launch guided tour.
struct OnboardingStep: Identifiable {
    enum ID: Int {
        case welcome
        case moodCheckIn
        case voiceReflection
        case wellnessTools
        case history
        case ready
    }

    let id: ID
    let title: String
    let description: String
    let highlightedElement: OnboardingHighlight?
    let preferredTooltipPosition: OnboardingTooltipPosition?

    var primaryButtonTitle: String {
        switch id {
        case .welcome:
            return "Start Tour"
        case .ready:
            return "Start Exploring"
        default:
            return "Next"
        }
    }

    static let tour: [OnboardingStep] = [
        OnboardingStep(
            id: .welcome,
            title: "Welcome to Nested 👋",
            description: "A quick tour of where things live.",
            highlightedElement: nil,
            preferredTooltipPosition: .centered
        ),
        OnboardingStep(
            id: .moodCheckIn,
            title: "Daily Mood Check-In",
            description: "Tap a mood to check in. Open the dropdown under it to see today’s entries.",
            highlightedElement: .moodCheckIn,
            preferredTooltipPosition: .above
        ),
        OnboardingStep(
            id: .voiceReflection,
            title: "Reflect Freely",
            description: "Speak or type what’s on your mind.",
            highlightedElement: .voiceReflection,
            preferredTooltipPosition: .above
        ),
        OnboardingStep(
            id: .wellnessTools,
            title: "Wellness Tools",
            description: "Quick calming tools when you need a reset.",
            highlightedElement: .wellnessTools,
            preferredTooltipPosition: .below
        ),
        OnboardingStep(
            id: .history,
            title: "Look Back and Learn",
            description: "Browse past moods and reflections here.",
            highlightedElement: .history,
            preferredTooltipPosition: .above
        ),
        OnboardingStep(
            id: .ready,
            title: "You're all set 🌱",
            description: "Your next check-in is only a tap away.",
            highlightedElement: nil,
            preferredTooltipPosition: .centered
        )
    ]
}
