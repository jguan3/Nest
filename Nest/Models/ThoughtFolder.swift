import Foundation
import SwiftData

/// A color-coded folder that groups captured thoughts by keyword.
@Model
final class ThoughtFolder {
    var id: UUID
    var name: String
    var keyword: String
    var colorName: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Thought.folder)
    var thoughts: [Thought]

    init(
        id: UUID = UUID(),
        name: String,
        keyword: String,
        colorName: String,
        sortOrder: Int,
        createdAt: Date = Date(),
        thoughts: [Thought] = []
    ) {
        self.id = id
        self.name = name
        self.keyword = keyword
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.thoughts = thoughts
    }

    /// Whether this folder is the fallback inbox (no spoken keyword).
    var isInbox: Bool {
        keyword.isEmpty
    }
}
