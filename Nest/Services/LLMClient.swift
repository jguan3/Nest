import Foundation

/// Contract for transcript analysis. Swap implementations without changing views.
protocol LLMClient: Sendable {
    func analyze(
        transcript: String,
        availableFolderNames: [String],
        systemPrompt: String
    ) async throws -> ReflectionAnalysis
}
