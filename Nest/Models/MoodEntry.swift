import Foundation
import SwiftData

/// A single mood check-in with a timestamp so feelings can change across the day.
@Model
final class MoodEntry {
    var id: UUID
    var moodRawValue: String
    var createdAt: Date
    var journalText: String?

    /// Creates a mood entry with an optional journal reflection.
    /// - Parameters:
    ///   - id: Stable identity for the entry.
    ///   - mood: The selected mood option.
    ///   - createdAt: When the check-in happened.
    ///   - journalText: Optional thoughts attached to the check-in.
    init(
        id: UUID = UUID(),
        mood: MoodOption,
        createdAt: Date = Date(),
        journalText: String? = nil
    ) {
        self.id = id
        self.moodRawValue = mood.rawValue
        self.createdAt = createdAt
        self.journalText = journalText
    }

    /// The resolved mood option, if the stored raw value is still valid.
    var mood: MoodOption? {
        MoodOption(rawValue: moodRawValue)
    }
}
