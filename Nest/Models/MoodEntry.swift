import Foundation
import SwiftData

/// A single mood check-in with a timestamp so feelings can change across the day.
@Model
final class MoodEntry {
    var id: UUID
    var moodRawValue: String
    var createdAt: Date

    /// Creates a mood entry for the given option at an optional timestamp.
    /// - Parameters:
    ///   - id: Stable identity for the entry.
    ///   - mood: The selected mood option.
    ///   - createdAt: When the check-in happened.
    init(
        id: UUID = UUID(),
        mood: MoodOption,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.moodRawValue = mood.rawValue
        self.createdAt = createdAt
    }

    /// The resolved mood option, if the stored raw value is still valid.
    var mood: MoodOption? {
        MoodOption(rawValue: moodRawValue)
    }
}
