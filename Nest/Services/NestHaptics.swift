import UIKit

/// Shared haptic helpers for soft Nest interactions.
enum NestHaptics {
    /// Plays a light impact suitable for taps and soft game feedback.
    static func softTap() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Plays a medium impact for slightly stronger feedback.
    static func mediumTap() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    private static var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: NestSettingsKeys.hapticsEnabled) as? Bool ?? true
    }
}
