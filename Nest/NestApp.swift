import SwiftData
import SwiftUI

@main
struct NestApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Thought.self, ThoughtFolder.self, MoodEntry.self]) { result in
            if case .success(let container) = result {
                SeedData.insertDefaultsIfNeeded(in: container.mainContext)
            }
        }
    }
}
