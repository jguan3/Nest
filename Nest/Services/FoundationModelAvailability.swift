import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Describes whether Apple’s on-device Foundation Models can power Nest.
enum FoundationModelAvailability: Equatable, Sendable {
    case available
    case unavailable(reason: String)

    /// Source label shown subtly in the Reflection UI.
    var sourceLabel: String {
        switch self {
        case .available:
            return "On-device Nest"
        case .unavailable:
            return "Offline Nest assistant"
        }
    }

    /// Reads current SystemLanguageModel availability.
    /// - Returns: `.available` when Apple Intelligence can run; otherwise a short reason.
    static func current() -> FoundationModelAvailability {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: humanReadableReason(reason))
        @unknown default:
            return .unavailable(reason: "Apple Intelligence isn’t available on this device right now.")
        }
        #else
        return .unavailable(reason: "Foundation Models aren’t available in this build.")
        #endif
    }

    #if canImport(FoundationModels)
    private static func humanReadableReason(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device doesn’t support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to use on-device Nest."
        case .modelNotReady:
            return "The on-device model isn’t ready yet. Nest can still reflect offline."
        @unknown default:
            return "Apple Intelligence isn’t available right now."
        }
    }
    #endif
}
