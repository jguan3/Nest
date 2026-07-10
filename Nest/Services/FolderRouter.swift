import Foundation

/// Routes a spoken transcript to a folder based on its leading keyword.
enum FolderRouter {
    /// Routes a transcript to the best matching folder using intent detection.
    /// - Parameters:
    ///   - transcript: The raw speech-to-text result.
    ///   - folders: Available folders to match against.
    /// - Returns: The destination folder and cleaned thought text.
    static func route(transcript: String, folders: [ThoughtFolder]) -> (folder: ThoughtFolder, cleanedText: String) {
        FolderIntentDetector.route(transcript: transcript, folders: folders)
    }
}
