import Testing
@testable import Nest

struct ReflectionEngineTests {
    @Test func stressMapsToCalmTheBody() {
        let result = ReflectionEngine.analyze(transcript: "I'm so stressed and my chest feels tight")
        #expect(result.recommendedTool == .guidedBreathing || result.recommendedTool == .softUnwind)
        #expect(!result.reflection.isEmpty)
        #expect(!result.reflection.contains("daily life has been weighing"))
    }

    @Test func overthinkingMapsToComeBackToNow() {
        let result = ReflectionEngine.analyze(transcript: "I keep overthinking everything and spiraling about the future")
        #expect(result.recommendedTool == .colorGrounding || result.recommendedTool == .ripplePond)
    }

    @Test func schoolStressMapsToHoldOneThing() {
        let result = ReflectionEngine.analyze(transcript: "I have three exams and I don't know where to start")
        #expect(result.recommendedTool == .focusBubble || result.recommendedTool == .worryBox)
    }

    @Test func sadnessMapsToPlaySoftly() {
        let result = ReflectionEngine.analyze(transcript: "I feel lonely and disappointed in myself")
        #expect(result.recommendedTool == .kindNote || result.recommendedTool == .bubbleDrift)
    }

    @Test func differentTranscriptsProduceDifferentReflections() {
        let stressed = ReflectionEngine.analyze(transcript: "I'm stressed about finals")
        let lonely = ReflectionEngine.analyze(transcript: "I feel lonely tonight")
        #expect(stressed.reflection != lonely.reflection)
        #expect(stressed.recommendedTool != lonely.recommendedTool || stressed.emotion != lonely.emotion)
    }
}
