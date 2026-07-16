import Foundation

/// In-session conversational reflection state shown after the first share is saved.
struct ReflectionConversation: Equatable {
    enum Phase: Equatable {
        case showingTurn(ReflectionTurn)
        case awaitingContinueInput
        case showingClosing(ReflectionClosing)
    }

    var phase: Phase
    var history: [ChatMessage]
    /// Subtle source label: on-device Nest vs offline Nest assistant.
    var sourceLabel: String
}
