import SwiftData
import Testing
@testable import Nest

@MainActor
struct FolderCreationTests {
  @Test func createsFolderWithKeywordFromName() throws {
    let container = try ModelContainer(
      for: Thought.self, ThoughtFolder.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let music = ThoughtFolder(name: "Music", keyword: "music", colorName: "purple", sortOrder: 0)
    let inbox = ThoughtFolder(name: "Inbox", keyword: "", colorName: "gray", sortOrder: 1)
    context.insert(music)
    context.insert(inbox)

    let school = try LibraryViewModel.createFolder(
      name: "School",
      colorName: "blue",
      folders: [music, inbox],
      in: context
    )

    #expect(school.name == "School")
    #expect(school.keyword == "school")
    #expect(inbox.sortOrder > school.sortOrder)
  }

  @Test func rejectsDuplicateKeywords() throws {
    let container = try ModelContainer(
      for: Thought.self, ThoughtFolder.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let music = ThoughtFolder(name: "Music", keyword: "music", colorName: "purple", sortOrder: 0)
    context.insert(music)

    #expect(throws: FolderCreationError.duplicateKeyword) {
      try LibraryViewModel.createFolder(
        name: "Music",
        colorName: "pink",
        folders: [music],
        in: context
      )
    }
  }
}
