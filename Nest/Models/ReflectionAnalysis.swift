import Foundation

/// Structured AI reflection returned from a single analysis request.
struct ReflectionAnalysis: Codable, Equatable {
    let reflection: String
    let stressor: String
    let emotion: String
    let recommendedTool: CopingTool
    /// Name of a user-created folder, or nil when none fits.
    let suggestedFolder: String?
    let crisis: Bool
}
