import Foundation

/// Provides calming affirmations for the Home screen.
enum AffirmationStore {
    static let affirmations: [String] = [
        "Your thoughts are welcome here.",
        "You don't have to finish everything today.",
        "One small breath is still progress.",
        "It's okay to start again.",
        "Your mind is allowed to wander and return.",
        "Soft effort still counts.",
        "You can put this down and pick it up later.",
        "You're not behind — you're arriving.",
        "Clarity comes in pieces.",
        "Rest is part of the work.",
        "Your ideas deserve a soft landing.",
        "There's room for unfinished thoughts.",
        "Gentle is a valid pace.",
        "You made it to this moment.",
        "Nothing needs to be perfect to be kept.",
        "Your attention is a gift, not a test.",
        "It's okay to need help holding things.",
        "You're allowed to take up quiet space.",
        "Even messy thoughts belong somewhere.",
        "Tomorrow can carry what today cannot."
    ]

    /// Returns a random affirmation, optionally avoiding the current one.
    /// - Parameter excluding: Affirmation to skip so the next feel different.
    /// - Returns: A random affirmation string.
    static func random(excluding current: String? = nil) -> String {
        let options = affirmations.filter { $0 != current }
        return options.randomElement() ?? affirmations[0]
    }
}
