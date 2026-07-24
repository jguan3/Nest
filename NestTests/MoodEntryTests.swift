import Foundation
import SwiftData
import Testing
@testable import Nest

@MainActor
struct MoodEntryTests {
    @Test func supportsEntriesWithoutJournalText() {
        let entry = MoodEntry(mood: .calm)

        #expect(entry.mood == .calm)
        #expect(entry.journalText == nil)
    }

    @Test func normalizesEmptyAndWhitespaceOnlyJournalText() {
        #expect(MoodStore.normalizedJournalText(nil) == nil)
        #expect(MoodStore.normalizedJournalText("") == nil)
        #expect(MoodStore.normalizedJournalText(" \n\t ") == nil)
        #expect(MoodStore.normalizedJournalText("  A quieter afternoon. \n") == "A quieter afternoon.")
    }

    @Test func persistsMoodTimestampAndJournalText() throws {
        let container = try ModelContainer(
            for: MoodEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let earliestExpectedDate = Date()

        let insertedEntry = try MoodStore.insert(
            .excited,
            journalText: "  Finished an important project.  ",
            in: context
        )
        let latestExpectedDate = Date()
        let savedEntries = try context.fetch(FetchDescriptor<MoodEntry>())

        #expect(savedEntries.count == 1)
        #expect(savedEntries.first?.id == insertedEntry.id)
        #expect(savedEntries.first?.mood == .excited)
        #expect(savedEntries.first?.journalText == "Finished an important project.")
        #expect(insertedEntry.createdAt >= earliestExpectedDate)
        #expect(insertedEntry.createdAt <= latestExpectedDate)
    }

    @Test func persistsEmptyJournalAsNil() throws {
        let container = try ModelContainer(
            for: MoodEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        try MoodStore.insert(.tired, journalText: "   ", in: context)
        let savedEntry = try #require(context.fetch(FetchDescriptor<MoodEntry>()).first)

        #expect(savedEntry.mood == .tired)
        #expect(savedEntry.journalText == nil)
    }
}
