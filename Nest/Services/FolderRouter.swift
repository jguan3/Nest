import Foundation

/// Routes a spoken transcript to a folder based on its leading keyword.
enum FolderRouter {
    struct RouteResult {
        let folderKeyword: String
        let cleanedText: String
    }

    /// Parses the first word of a transcript and returns routing info.
    /// - Parameter transcript: The raw speech-to-text result.
    /// - Returns: The matched keyword (empty if none) and the text with the keyword stripped.
    static func parse(transcript: String) -> RouteResult {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return RouteResult(folderKeyword: "", cleanedText: "")
        }

        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let firstToken = String(parts[0])
        let keyword = firstToken
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters)

        let remainder: String
        if parts.count > 1 {
            remainder = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            remainder = ""
        }

        return RouteResult(folderKeyword: keyword, cleanedText: remainder)
    }

    /// Routes a transcript to the best matching folder.
    /// - Parameters:
    ///   - transcript: The raw speech-to-text result.
    ///   - folders: Available folders to match against.
    /// - Returns: The destination folder and cleaned thought text.
    static func route(transcript: String, folders: [ThoughtFolder]) -> (folder: ThoughtFolder, cleanedText: String) {
        let parsed = parse(transcript: transcript)
        let inbox = folders.first(where: \.isInbox) ?? folders.last!

        guard !parsed.folderKeyword.isEmpty else {
            return (inbox, parsed.cleanedText)
        }

        if let matched = folders.first(where: {
            !$0.isInbox && $0.keyword.lowercased() == parsed.folderKeyword
        }) {
            let text = parsed.cleanedText.isEmpty ? parsed.folderKeyword.capitalized : parsed.cleanedText
            return (matched, text)
        }

        return (inbox, trimmedTranscript(transcript))
    }

    private static func trimmedTranscript(_ transcript: String) -> String {
        transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
