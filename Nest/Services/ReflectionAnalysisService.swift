import Foundation

/// Orchestrates LLM analysis and folder resolution.
struct ReflectionAnalysisService {
    let llmClient: any LLMClient

    init(llmClient: any LLMClient = MockLLMClient()) {
        self.llmClient = llmClient
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
            crisis: false
        )
    }
}
