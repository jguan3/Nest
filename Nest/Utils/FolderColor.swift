import SwiftUI

/// Preset folder colors for visual differentiation.
enum FolderColor: String, CaseIterable {
    case purple
    case blue
    case green
    case orange
    case pink
    case gray

    /// Colors users can pick when creating a folder.
    static var selectable: [FolderColor] {
        allCases.filter { $0 != .gray }
    }

    /// Resolves the preset to a SwiftUI color.
    var color: Color {
        switch self {
        case .purple: Color(red: 0.62, green: 0.45, blue: 0.98)
        case .blue: Color(red: 0.35, green: 0.62, blue: 1.0)
        case .green: Color(red: 0.35, green: 0.82, blue: 0.62)
        case .orange: Color(red: 1.0, green: 0.62, blue: 0.35)
        case .pink: Color(red: 0.98, green: 0.45, blue: 0.72)
        case .gray: Color(red: 0.55, green: 0.58, blue: 0.65)
        }
    }

    /// A soft gradient for folder accents and chips.
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Returns the color for a stored color name, defaulting to gray.
    /// - Parameter name: The persisted color key.
    static func from(name: String) -> Color {
        FolderColor(rawValue: name)?.color ?? .gray
    }

    /// Returns the gradient for a stored color name.
    /// - Parameter name: The persisted color key.
    static func gradient(for name: String) -> LinearGradient {
        FolderColor(rawValue: name)?.gradient ?? FolderColor.gray.gradient
    }
}
