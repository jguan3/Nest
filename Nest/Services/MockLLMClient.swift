import Foundation

/// Deterministic stand-in for LLM analysis while provider architecture is deferred.
struct MockLLMClient: LLMClient {
    var simulatedDelay: Duration = .seconds(1)

    func analyze(
        transcript: String,
        availableFolderNames: [String],
        systemPrompt: String
    ) async throws -> ReflectionAnalysis {
        try await Task.sleep(for: simulatedDelay)

        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if lower.contains("crisis") || lower.contains("kill myself") || lower.contains("want to die") {
            return ReflectionAnalysis(
                reflection: "Thank you for sharing something so heavy. You deserve support right now.",
                stressor: "crisis",
                emotion: "distress",
                recommendedTool: .guidedBreathing,
                suggestedFolder: nil,
                crisis: true
            )
        }

        let matchedFolder = availableFolderNames.first { folderName in
            lower.contains(folderName.lowercased())
        }

        let result = ReflectionEngine.analyze(transcript: trimmed)

        return ReflectionAnalysis(
            reflection: result.reflection,
            stressor: result.stressor,
            emotion: result.emotion,
            recommendedTool: result.recommendedTool,
            suggestedFolder: matchedFolder,
            crisis: false
        )
    }
}
