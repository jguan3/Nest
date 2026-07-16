import Foundation

/// Chooses Foundation Models when available, otherwise MockLLMClient.
enum ChatClientRouter {
    /// Resolves the chat client Nest should use for conversational reflection.
    /// - Returns: A ChatClient plus a short source label for the UI.
    static func makeClient() -> (client: any ChatClient, sourceLabel: String) {
        let availability = FoundationModelAvailability.current()
        switch availability {
        case .available:
            return (FoundationModelsChatClient(), availability.sourceLabel)
        case .unavailable:
            return (MockLLMClient(simulatedDelay: .milliseconds(450)), availability.sourceLabel)
        }
    }
}
