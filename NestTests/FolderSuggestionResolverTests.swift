import Testing
@testable import Nest

struct FolderSuggestionResolverTests {
    private func makeFolders() -> [ThoughtFolder] {
        [
            ThoughtFolder(name: "Finals Week", keyword: "finals week", colorName: "purple", sortOrder: 0),
            ThoughtFolder(name: "Inbox", keyword: "", colorName: "gray", sortOrder: 1),
        ]
    }

    @Test func exactMatchResolvesUserFolder() {
        let folders = makeFolders()
        let resolved = FolderSuggestionResolver.resolve(suggestedFolder: "Finals Week", folders: folders)
        #expect(resolved.name == "Finals Week")
    }

    @Test func fuzzyMatchResolvesCloseName() {
        let folders = makeFolders()
        let resolved = FolderSuggestionResolver.resolve(suggestedFolder: "Final Week", folders: folders)
        #expect(resolved.name == "Finals Week")
    }

    @Test func nilSuggestionFallsBackToInbox() {
        let folders = makeFolders()
        let resolved = FolderSuggestionResolver.resolve(suggestedFolder: nil, folders: folders)
        #expect(resolved.name == "Inbox")
    }

    @Test func unknownSuggestionFallsBackToInbox() {
        let folders = makeFolders()
        let resolved = FolderSuggestionResolver.resolve(suggestedFolder: "Relationships", folders: folders)
        #expect(resolved.name == "Inbox")
    }
}
