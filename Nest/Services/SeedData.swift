import Foundation
import SwiftData

/// Inserts default folders on first launch.
enum SeedData {
    /// Creates Music and Inbox folders if none exist.
    /// - Parameter context: The SwiftData model context.
    static func insertDefaultsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<ThoughtFolder>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let music = ThoughtFolder(
            name: "Music",
            keyword: "music",
            colorName: FolderColor.purple.rawValue,
            sortOrder: 0
        )
        let inbox = ThoughtFolder(
            name: "Inbox",
            keyword: "",
            colorName: FolderColor.gray.rawValue,
            sortOrder: 1
        )

        context.insert(music)
        context.insert(inbox)
        try? context.save()
    }
}
