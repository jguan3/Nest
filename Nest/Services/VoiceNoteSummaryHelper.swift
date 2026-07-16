import Foundation

/// Builds short history title and preview strings from a voice-note transcript.
enum VoiceNoteSummaryHelper {
    private static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "but", "if", "in", "on", "at", "to", "for",
        "of", "is", "it", "i", "im", "i'm", "me", "my", "we", "you", "that", "this",
        "was", "were", "be", "been", "am", "are", "as", "with", "just", "really",
        "very", "so", "like", "about", "from", "have", "has", "had", "do", "does",
        "did", "not", "no", "yes", "um", "uh", "kinda", "kind", "sort", "of"
    ]

    /// Creates a short title and one-line preview for a voice note.
    /// - Parameter transcript: Raw user transcript or display text.
    /// - Returns: Title (~3–8 words) and preview (~10–20 words).
    static func summarize(transcript: String) -> (title: String, preview: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "Voice memo" else {
            return ("Voice memo", "A short voice note.")
        }

        let words = trimmed
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let meaningful = words.filter { word in
            !stopWords.contains(word.lowercased())
        }

        let titleSource = meaningful.isEmpty ? words : meaningful
        let titleWords = Array(titleSource.prefix(6))
        let title = titleWords.isEmpty
            ? "Voice memo"
            : titleWords.joined(separator: " ").capitalized

        let previewWords = Array(words.prefix(16))
        let preview = previewWords.isEmpty
            ? "A short voice note."
            : previewWords.joined(separator: " ") + (words.count > 16 ? "…" : "")

        return (title, preview)
    }

    /// Title to show in history when a stored title is missing.
    /// - Parameter thought: Saved voice note.
    /// - Returns: Stored title, or a fallback summary from transcript/text.
    static func displayTitle(for thought: Thought) -> String {
        let stored = thought.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty { return stored }
        let source = thought.fullTranscript ?? thought.text
        return summarize(transcript: source).title
    }

    /// Preview to show in history when a stored preview is missing.
    /// - Parameter thought: Saved voice note.
    /// - Returns: Stored preview, or a fallback summary from transcript/text.
    static func displayPreview(for thought: Thought) -> String {
        let stored = thought.preview.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty { return stored }
        let source = thought.fullTranscript ?? thought.text
        return summarize(transcript: source).preview
    }
}
