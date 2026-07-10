import AVFoundation
import Foundation

/// Persists voice memo audio files in the app documents directory.
enum AudioFileStore {
    private static let directoryName = "VoiceMemos"

    /// Returns the voice memos directory, creating it if needed.
    static var directoryURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    /// Creates a unique file URL for a new PCM recording.
    static func makeRecordingURL() -> URL {
        directoryURL.appendingPathComponent("\(UUID().uuidString).caf")
    }

    /// Resolves a stored file name to a full URL.
    /// - Parameter fileName: The persisted audio file name.
    static func url(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    /// Deletes an audio file from disk.
    /// - Parameter fileName: The persisted audio file name.
    static func delete(fileName: String) {
        let url = url(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
