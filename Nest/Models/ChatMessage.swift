import Foundation

/// A single turn in a reflection conversation.
struct ChatMessage: Identifiable, Equatable, Sendable {
    enum Role: String, Equatable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String

    /// Creates a chat message.
    /// - Parameters:
    ///   - id: Stable identity for the message; defaults to a new UUID.
    ///   - role: Whether the speaker is the user or Nest.
    ///   - text: Plain text content (voice is converted to text before this point).
    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
