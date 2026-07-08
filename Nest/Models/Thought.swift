import Foundation
import SwiftData

/// A single captured thought saved as speech-to-text.
@Model
final class Thought {
    var id: UUID
    var text: String
    var createdAt: Date

    var folder: ThoughtFolder?

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        folder: ThoughtFolder? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.folder = folder
    }
}
