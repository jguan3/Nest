import Testing
@testable import Nest

struct ReflectionAnalysisParsingTests {
    @Test func mockClientReturnsCrisisForSelfHarmLanguage() async throws {
        let client = MockLLMClient(simulatedDelay: .milliseconds(10))
        let analysis = try await client.analyze(
            transcript: "I want to die and I don't know what to do",
            availableFolderNames: [],
            systemPrompt: ""
        )

        #expect(analysis.crisis == true)
    }

    @Test func mockClientSuggestsMatchingFolder() async throws {
        let client = MockLLMClient(simulatedDelay: .milliseconds(10))
        let analysis = try await client.analyze(
            transcript: "My finals week schedule is completely overwhelming",
            availableFolderNames: ["Finals Week", "Work"],
            systemPrompt: ""
        )

        #expect(analysis.crisis == false)
        #expect(analysis.suggestedFolder == "Finals Week")
        #expect(!analysis.reflection.isEmpty)
    }

    @Test func reflectionServiceAcceptsVeryShortTranscript() async throws {
        let service = ReflectionAnalysisService(llmClient: MockLLMClient(simulatedDelay: .zero))
        let folders = [ThoughtFolder(name: "Inbox", keyword: "", colorName: "gray", sortOrder: 0)]

        let analysis = try await service.analyze(transcript: "I'm stressed", availableFolders: folders)

        #expect(analysis.crisis == false)
        #expect(!analysis.reflection.isEmpty)
        #expect(analysis.recommendedTool == .guidedBreathing || analysis.recommendedTool == .softUnwind)
        #expect(!analysis.reflection.lowercased().contains("try sharing"))
        #expect(!analysis.reflection.lowercased().contains("too short"))
    }

    @Test func fallbackAnalysisIsNonCrisis() {
        let fallback = ReflectionAnalysisService.fallback()
        #expect(fallback.crisis == false)
        #expect(fallback.suggestedFolder == nil)
        #expect(fallback.recommendedTool == .guidedBreathing)
    }
}
