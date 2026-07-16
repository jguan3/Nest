import Foundation

/// Contract for conversational reflection. Implementations receive plain text only.
protocol ChatClient: Sendable {
    /// Produces Nest’s companion reply for a user message.
    /// - Parameters:
    ///   - userMessage: Final text from voice STT or typing.
    ///   - history: Prior turns in this reflection session (excluding the new user message).
    /// - Returns: A warm reflection turn with optional follow-up.
    func reflectionTurn(for userMessage: String, history: [ChatMessage]) async throws -> ReflectionTurn

    /// Produces a closing summary and personalized activity invitations.
    /// - Parameter history: Full session history including user and assistant messages.
    /// - Returns: Summary plus 2–3 optional Nest activities.
    func reflectionClosing(history: [ChatMessage]) async throws -> ReflectionClosing
}
