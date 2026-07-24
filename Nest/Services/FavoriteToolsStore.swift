import Foundation

/// Stores which coping tools the user has favorited.
enum FavoriteToolsStore {
    static let storageKey = "nest.favoriteTools"

    /// Parses a comma-separated favorites string into tools.
    /// - Parameter raw: Persisted raw-value list.
    /// - Returns: Favorited tools in stored order.
    static func tools(from raw: String) -> [CopingTool] {
        raw.split(separator: ",")
            .compactMap { CopingTool(rawValue: String($0).trimmingCharacters(in: .whitespaces)) }
    }

    /// Serializes favorited tools for AppStorage.
    /// - Parameter tools: Favorited tools.
    /// - Returns: Comma-separated raw values.
    static func rawValue(from tools: [CopingTool]) -> String {
        tools.map(\.rawValue).joined(separator: ",")
    }

    /// Toggles a tool in the favorites list.
    /// - Parameters:
    ///   - tool: Tool to add or remove.
    ///   - raw: Current persisted favorites string.
    /// - Returns: Updated persisted favorites string.
    static func toggling(_ tool: CopingTool, in raw: String) -> String {
        var tools = tools(from: raw)
        if let index = tools.firstIndex(of: tool) {
            tools.remove(at: index)
        } else {
            tools.append(tool)
        }
        return rawValue(from: tools)
    }

    /// Whether a tool is currently favorited.
    /// - Parameters:
    ///   - tool: Tool to check.
    ///   - raw: Current persisted favorites string.
    /// - Returns: `true` when the tool is favorited.
    static func contains(_ tool: CopingTool, in raw: String) -> Bool {
        tools(from: raw).contains(tool)
    }
}
