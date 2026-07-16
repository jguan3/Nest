import Foundation

/// Distinguishes self-harm crisis language from violent intent toward others.
///
/// Self-harm routes to suicide/crisis lifelines. Harm toward others uses
/// de-escalation guidance and emergency services when immediate risk is present.
enum CrisisKind: String, Codable, Equatable, Sendable {
    case none
    case selfHarm
    case harmToOthers

    /// Whether this kind should interrupt normal reflection.
    /// - Returns: True when Nest should leave the reflective conversation flow.
    var interruptsReflection: Bool {
        self != .none
    }
}
