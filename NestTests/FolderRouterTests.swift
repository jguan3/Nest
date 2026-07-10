import Testing
@testable import Nest

struct FolderRouterTests {
  private func makeFolders() -> [ThoughtFolder] {
    [
      ThoughtFolder(name: "Music", keyword: "music", colorName: "purple", sortOrder: 0),
      ThoughtFolder(name: "Inbox", keyword: "", colorName: "gray", sortOrder: 1),
    ]
  }

  @Test func routesMusicKeywordToMusicFolder() {
    let folders = makeFolders()
    let result = FolderRouter.route(
      transcript: "Music I saw your face in the crowd tonight",
      folders: folders
    )

    #expect(result.folder.name == "Music")
    #expect(result.cleanedText == "I saw your face in the crowd tonight")
  }

  @Test func routesMusicWithCommaToMusicFolder() {
    let folders = makeFolders()
    let result = FolderRouter.route(
      transcript: "music, i like to play the piano",
      folders: folders
    )

    #expect(result.folder.name == "Music")
    #expect(result.cleanedText == "i like to play the piano")
  }

  @Test func routesUnknownKeywordToInbox() {
    let folders = makeFolders()
    let result = FolderRouter.route(
      transcript: "School finish the essay draft",
      folders: folders
    )

    #expect(result.folder.name == "Inbox")
    #expect(result.cleanedText == "School finish the essay draft")
  }

  @Test func handlesKeywordOnlyTranscript() {
    let folders = makeFolders()
    let result = FolderRouter.route(transcript: "Music", folders: folders)

    #expect(result.folder.name == "Music")
    #expect(result.cleanedText == "Music")
  }
}
