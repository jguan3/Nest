import Foundation

/// Closing companion reply after the user finishes reflecting.
struct ReflectionClosing: Equatable, Sendable {
    /// Short summary of what they shared across the session.
    let summary: String
    /// Invitation line introducing optional activities.
    let invitationLine: String
    /// Two or three personalized Nest activities (optional choices).
    let suggestedActivities: [CopingTool]

    /// Default invitation copy for activity suggestions.
    static let defaultInvitationLine = "Based on what you shared, here are a few things that might help:"
}
