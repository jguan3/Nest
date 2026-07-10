import Foundation
import SwiftData

/// A single captured thought saved as speech-to-text with optional voice memo audio.
@Model
final class Thought {
    var id: UUID
    var text: String
    var fullTranscript: String?
    var createdAt: Date
    var audioFileName: String?
    var duration: TimeInterval

    var folder: ThoughtFolder?

    init(
        id: UUID = UUID(),
        text: String,
        fullTranscript: String? = nil,
        createdAt: Date = Date(),
        audioFileName: String? = nil,
        duration: TimeInterval = 0,
        folder: ThoughtFolder? = nil
    ) {
        self.id = id
        self.text = text
        self.fullTranscript = fullTranscript
        self.createdAt = createdAt
        self.audioFileName = audioFileName
        self.duration = duration
        self.folder = folder
    }

    /// Whether this thought has a saved voice memo.
    var hasVoiceMemo: Bool {
        audioFileName != nil
    }

    /// Whether a usable transcription exists.
    var hasTranscription: Bool {
        if let fullTranscript, !fullTranscript.isEmpty { return true }
        return !text.isEmpty && text != "Voice memo"
    }

    /// Formatted duration string for display (e.g. "0:07").
    var formattedDuration: String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
