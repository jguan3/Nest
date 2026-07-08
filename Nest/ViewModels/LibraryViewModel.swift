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
        modelContext.delete(thought)
        try? modelContext.save()
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
