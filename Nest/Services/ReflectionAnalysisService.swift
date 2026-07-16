import Foundation

/// Orchestrates LLM analysis and folder resolution.
struct ReflectionAnalysisService {
    let llmClient: any LLMClient

    /// Creates an analysis service backed by the given LLM client.
    /// - Parameter llmClient: Client used for transcript analysis; defaults to `MockLLMClient`.
    init(llmClient: (any LLMClient)? = nil) {
        // Build the default client in the initializer body (not a default argument)
        // so MainActor isolation stays safe under Swift 6 / default actor isolation.
        self.llmClient = llmClient ?? MockLLMClient()
    }

    func analyze(transcript: String, availableFolders: [ThoughtFolder]) async throws -> ReflectionAnalysis {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let folderNames = availableFolders.filter { !$0.isInbox }.map(\.name)
        let systemPrompt = ReflectionPromptBuilder.systemPrompt(availableFolderNames: folderNames)

        return try await llmClient.analyze(
            transcript: trimmed,
            availableFolderNames: folderNames,
            systemPrompt: systemPrompt
        )
    }

    /// Fallback analysis when the LLM is unavailable.
    static func fallback() -> ReflectionAnalysis {
        ReflectionAnalysis(
            reflection: "I saved your thoughts. I wasn't able to reflect on them right now — you can revisit them in your library.",
            stressor: "unknown",
            emotion: "unknown",
            recommendedTool: .guidedBreathing,
            suggestedFolder: nil,
            crisisKind: .none
        )
    }
}
