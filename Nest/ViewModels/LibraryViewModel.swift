import Foundation
import SwiftData

/// Read-only library state derived from SwiftData folders.
struct LibraryFolderSection: Identifiable {
    let id: UUID
    let folder: ThoughtFolder
    let thoughts: [Thought]
}

/// Groups folders and thoughts for the accordion library UI.
@MainActor
enum LibraryViewModel {
    /// Builds sorted accordion sections from folders.
    /// - Parameter folders: All folders from SwiftData.
    /// - Returns: Sections with thoughts sorted newest first.
    static func sections(from folders: [ThoughtFolder]) -> [LibraryFolderSection] {
        folders
            .sorted { lhs, rhs in
                if lhs.isInbox != rhs.isInbox { return !lhs.isInbox }
                return lhs.sortOrder < rhs.sortOrder
            }
            .map { folder in
                let sortedThoughts = folder.thoughts.sorted { $0.createdAt > $1.createdAt }
                return LibraryFolderSection(id: folder.id, folder: folder, thoughts: sortedThoughts)
            }
    }

    /// Creates a new user-defined folder with a spoken keyword matching its name.
    /// - Parameters:
    ///   - name: Display name and spoken keyword source.
    ///   - colorName: Preset color key from `FolderColor`.
    ///   - folders: Existing folders for validation and sort order.
    ///   - modelContext: SwiftData context.
    /// - Returns: The newly created folder.
    @discardableResult
    static func createFolder(
        name: String,
        colorName: String,
        folders: [ThoughtFolder],
        in modelContext: ModelContext
    ) throws -> ThoughtFolder {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FolderCreationError.emptyName
        }

        let keyword = trimmedName.lowercased()
        let keywordTaken = folders.contains { !$0.isInbox && $0.keyword == keyword }
        guard !keywordTaken else {
            throw FolderCreationError.duplicateKeyword
        }

        let userFolders = folders.filter { !$0.isInbox }
        let nextOrder = (userFolders.map(\.sortOrder).max() ?? -1) + 1

        let folder = ThoughtFolder(
            name: trimmedName,
            keyword: keyword,
            colorName: colorName,
            sortOrder: nextOrder
        )
        modelContext.insert(folder)

        if let inbox = folders.first(where: \.isInbox) {
            inbox.sortOrder = nextOrder + 1
        }

        try modelContext.save()
        return folder
    }

    /// Deletes a thought from the model context.
    /// - Parameters:
    ///   - thought: The thought to remove.
    ///   - modelContext: SwiftData context.
    static func delete(_ thought: Thought, in modelContext: ModelContext) {
        if let fileName = thought.audioFileName {
            AudioFileStore.delete(fileName: fileName)
        }
        modelContext.delete(thought)
        try? modelContext.save()
    }

    /// Loads or generates an AI transcription for a voice memo.
    /// - Parameters:
    ///   - thought: The memo to transcribe.
    ///   - folders: All folders for updating cleaned text if needed.
    ///   - modelContext: SwiftData context.
    /// - Returns: The full transcribed text to display.
    static func loadTranscription(
        for thought: Thought,
        folders: [ThoughtFolder],
        in modelContext: ModelContext
    ) async -> String {
        if let fullTranscript = thought.fullTranscript, !fullTranscript.isEmpty {
            return fullTranscript
        }

        if let fileName = thought.audioFileName {
            let url = AudioFileStore.url(for: fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                let transcript = await TranscriptionService.transcribeAudio(at: url)
                if !transcript.isEmpty {
                    thought.fullTranscript = transcript
                    if thought.text == "Voice memo" || thought.text.isEmpty {
                        let route = FolderRouter.route(transcript: transcript, folders: folders)
                        thought.text = route.cleanedText.isEmpty ? transcript : route.cleanedText
                    }
                    try? modelContext.save()
                    return transcript
                }
            }
        }

        if thought.hasTranscription {
            return thought.text
        }

        return "Couldn't transcribe this memo. Check your connection and try again."
    }

    /// Renames a folder and updates its spoken keyword.
    /// - Parameters:
    ///   - folder: The folder to rename.
    ///   - newName: The new display name.
    ///   - folders: All folders for duplicate checking.
    ///   - modelContext: SwiftData context.
    static func renameFolder(
        _ folder: ThoughtFolder,
        to newName: String,
        folders: [ThoughtFolder],
        in modelContext: ModelContext
    ) throws {
        guard !folder.isInbox else { throw FolderManagementError.cannotEditInbox }

        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw FolderCreationError.emptyName }

        let keyword = trimmedName.lowercased()
        let keywordTaken = folders.contains {
            $0.id != folder.id && !$0.isInbox && $0.keyword == keyword
        }
        guard !keywordTaken else { throw FolderCreationError.duplicateKeyword }

        folder.name = trimmedName
        folder.keyword = keyword
        try modelContext.save()
    }

    /// Deletes a folder and moves its thoughts to Inbox.
    /// - Parameters:
    ///   - folder: The folder to delete.
    ///   - folders: All folders to locate Inbox.
    ///   - modelContext: SwiftData context.
    static func deleteFolder(
        _ folder: ThoughtFolder,
        folders: [ThoughtFolder],
        in modelContext: ModelContext
    ) throws {
        guard !folder.isInbox else { throw FolderManagementError.cannotEditInbox }

        guard let inbox = folders.first(where: \.isInbox) else {
            throw FolderManagementError.inboxMissing
        }

        for thought in folder.thoughts {
            thought.folder = inbox
        }

        modelContext.delete(folder)
        try modelContext.save()
        normalizeSortOrders(folders: folders.filter { $0.id != folder.id }, in: modelContext)
    }

    /// Reorders user folders to match the provided sequence.
    /// - Parameters:
    ///   - orderedFolders: Folders in the desired order (excluding Inbox).
    ///   - allFolders: All folders including Inbox.
    ///   - modelContext: SwiftData context.
    static func moveFolders(
        _ orderedFolders: [ThoughtFolder],
        allFolders: [ThoughtFolder],
        in modelContext: ModelContext
    ) {
        for (index, folder) in orderedFolders.enumerated() where !folder.isInbox {
            folder.sortOrder = index
        }

        if let inbox = allFolders.first(where: \.isInbox) {
            inbox.sortOrder = orderedFolders.filter { !$0.isInbox }.count
        }

        try? modelContext.save()
    }

    private static func normalizeSortOrders(folders: [ThoughtFolder], in modelContext: ModelContext) {
        let userFolders = folders.filter { !$0.isInbox }.sorted { $0.sortOrder < $1.sortOrder }
        moveFolders(userFolders, allFolders: folders, in: modelContext)
    }
}

/// Validation errors when creating a folder.
enum FolderCreationError: LocalizedError {
    case emptyName
    case duplicateKeyword

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Enter a folder name."
        case .duplicateKeyword:
            "A folder with that keyword already exists."
        }
    }
}

/// Validation errors when managing folders.
enum FolderManagementError: LocalizedError {
    case cannotEditInbox
    case inboxMissing

    var errorDescription: String? {
        switch self {
        case .cannotEditInbox:
            "The Inbox folder cannot be changed."
        case .inboxMissing:
            "Inbox folder is missing."
        }
    }
}
