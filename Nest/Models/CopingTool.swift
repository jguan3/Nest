import Foundation
import SwiftUI

/// Coping tools available in Nest that the AI may recommend.
enum CopingTool: String, CaseIterable, Codable, Equatable, Identifiable {
    case guidedBreathing
    case softUnwind
    case softFocusBeats
    case colorGrounding
    case ripplePond
    case focusBubble
    case worryBox
    case bubbleDrift
    case kindNote

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .guidedBreathing: "Guided Breathing"
        case .softUnwind: "Soft Unwind"
        case .softFocusBeats: "Soft Focus Beats"
        case .colorGrounding: "Color Grounding"
        case .ripplePond: "Ripple Pond"
        case .focusBubble: "Focus Bubble"
        case .worryBox: "Worry Box"
        case .bubbleDrift: "Bubble Drift"
        case .kindNote: "Kind Note"
        }
    }

    var subtitle: String {
        switch self {
        case .guidedBreathing: "Inhale and exhale with a calm expanding circle"
        case .softUnwind: "A gentle body check-in for releasing tension"
        case .softFocusBeats: "Loop soft ADHD-friendly focus music"
        case .colorGrounding: "Find something that matches a random niche color"
        case .ripplePond: "Tap the water and watch soft ripples fade"
        case .focusBubble: "A quiet timer to hold one task at a time"
        case .worryBox: "Write a worry, seal it, then release it"
        case .bubbleDrift: "A chill game — soft bubbles, no pressure"
        case .kindNote: "Write yourself the words you'd give a friend"
        }
    }

    var systemImage: String {
        switch self {
        case .guidedBreathing: "wind"
        case .softUnwind: "figure.mind.and.body"
        case .softFocusBeats: "headphones"
        case .colorGrounding: "eyedropper.halffull"
        case .ripplePond: "water.waves"
        case .focusBubble: "circle.dotted"
        case .worryBox: "archivebox.fill"
        case .bubbleDrift: "bubbles.and.sparkles"
        case .kindNote: "heart.text.square.fill"
        }
    }

    /// Nest Tools section this activity belongs to.
    var categoryLabel: String {
        switch self {
        case .guidedBreathing, .softUnwind, .softFocusBeats: "Calm the body"
        case .colorGrounding, .ripplePond: "Come back to now"
        case .focusBubble, .worryBox: "Hold one thing"
        case .bubbleDrift, .kindNote: "Play softly"
        }
    }

    /// Accent color used on the Tools hub card.
    var tint: Color {
        switch self {
        case .guidedBreathing: Color(red: 0.55, green: 0.7, blue: 1.0)
        case .softUnwind: Color(red: 0.55, green: 0.85, blue: 0.65)
        case .softFocusBeats: Color(red: 0.45, green: 0.75, blue: 0.95)
        case .colorGrounding: Color(red: 0.95, green: 0.65, blue: 0.45)
        case .ripplePond: Color(red: 0.45, green: 0.7, blue: 0.9)
        case .focusBubble: Color(red: 0.7, green: 0.55, blue: 1.0)
        case .worryBox: Color(red: 0.8, green: 0.6, blue: 0.4)
        case .bubbleDrift: Color(red: 0.75, green: 0.6, blue: 1.0)
        case .kindNote: Color(red: 1.0, green: 0.55, blue: 0.7)
        }
    }
}
