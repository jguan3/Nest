import Foundation
import SwiftData

/// Inserts default folders on first launch and runs one-time migrations.
enum SeedData {
    private static let musicMigrationKey = "nest.migration.musicFolderRemoved"

    /// Creates Inbox on first launch and migrates the legacy Music seed folder.
    static func insertDefaultsIfNeeded(in context: ModelContext) {
        var folders = (try? context.fetch(FetchDescriptor<ThoughtFolder>())) ?? []

        if folders.isEmpty {
            let inbox = ThoughtFolder(
                name: "Inbox",
                keyword: "",
                colorName: FolderColor.gray.rawValue,
                sortOrder: 0
            )
            context.insert(inbox)
            try? context.save()
            folders = (try? context.fetch(FetchDescriptor<ThoughtFolder>())) ?? []
        }

        migrateLegacyMusicFolderIfNeeded(in: context, folders: folders)
    }

    /// Removes the seeded Music placeholder and moves its thoughts to Inbox.
    private static func migrateLegacyMusicFolderIfNeeded(
        in context: ModelContext,
        folders: [ThoughtFolder]
    ) {
        guard !UserDefaults.standard.bool(forKey: musicMigrationKey) else { return }

        guard let musicFolder = folders.first(where: {
            $0.name == "Music" && $0.keyword == "music"
        }) else {
            UserDefaults.standard.set(true, forKey: musicMigrationKey)
            return
        }

        let inbox = folders.first(where: \.isInbox)
        for thought in musicFolder.thoughts {
            thought.folder = inbox
            inbox?.thoughts.append(thought)
        }

        context.delete(musicFolder)
        try? context.save()
        UserDefaults.standard.set(true, forKey: musicMigrationKey)
    }
}
