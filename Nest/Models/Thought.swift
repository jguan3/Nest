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
    var reflection: String?
    var stressor: String?
    var emotion: String?
    var recommendedToolRaw: String?
    var isCrisis: Bool

    var folder: ThoughtFolder?

    init(
        id: UUID = UUID(),
        text: String,
        fullTranscript: String? = nil,
        createdAt: Date = Date(),
        audioFileName: String? = nil,
        duration: TimeInterval = 0,
        reflection: String? = nil,
        stressor: String? = nil,
        emotion: String? = nil,
        recommendedToolRaw: String? = nil,
        isCrisis: Bool = false,
        folder: ThoughtFolder? = nil
    ) {
        self.id = id
        self.text = text
        self.fullTranscript = fullTranscript
        self.createdAt = createdAt
        self.audioFileName = audioFileName
        self.duration = duration
        self.reflection = reflection
        self.stressor = stressor
        self.emotion = emotion
        self.recommendedToolRaw = recommendedToolRaw
        self.isCrisis = isCrisis
        self.folder = folder
    }

    /// Recommended coping tool from AI reflection, if available.
    var recommendedTool: CopingTool? {
        guard let recommendedToolRaw else { return nil }
        return CopingTool(rawValue: recommendedToolRaw)
    }

    /// Whether a saved AI reflection exists.
    var hasReflection: Bool {
        if let reflection, !reflection.isEmpty { return true }
        return false
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
