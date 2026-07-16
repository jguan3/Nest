import Foundation

/// Nest’s companion reply after the user shares a reflection turn.
struct ReflectionTurn: Equatable, Sendable {
    /// Warm reflection of what the user shared (soft language only).
    let reflection: String
    /// Soft theme notes grounded in what they said (not diagnoses).
    let themeNotes: [String]
    /// Optional gentle follow-up; nil when a one-shot pause fits better.
    let followUpQuestion: String?
    /// True when Nest senses a natural stopping point.
    let feelsNaturalPause: Bool
    /// Which safety interrupt applies, if any.
    let crisisKind: CrisisKind
    /// Primary Nest activity hint for personalization and Library save.
    let recommendedTool: CopingTool
    /// Brief situational stressor label for persistence (not shown as a diagnosis).
    let stressor: String
    /// Soft emotion/theme label for persistence.
    let emotion: String
    /// History title for the note; set only on the initial turn, empty on follow-ups.
    let title: String
    /// History preview for the note; set only on the initial turn, empty on follow-ups.
    let preview: String

    /// Whether this turn should interrupt normal reflection (any crisis kind).
    var crisis: Bool { crisisKind.interruptsReflection }

    /// Flattens turn content into assistant message text for history.
    /// - Returns: Combined reflection and optional follow-up for the session transcript.
    var assistantHistoryText: String {
        if let followUpQuestion, !followUpQuestion.isEmpty {
            return "\(reflection)\n\n\(followUpQuestion)"
        }
        return reflection
    }
}
