import Testing
@testable import Nest

@MainActor
struct ConversationalReflectionTests {
    @Test func mockReflectionTurnUsesSoftLanguage() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let turn = try await client.reflectionTurn(
            for: "I'm so stressed about exams and I don't know where to start",
            history: []
        )

        let lowerReflection = turn.reflection.lowercased()
        #expect(!turn.crisis)
        #expect(!turn.reflection.isEmpty)
        #expect(!lowerReflection.contains("you are anxious"))
        #expect(!lowerReflection.contains("you are overwhelmed"))
        #expect(
            lowerReflection.contains("sounds like")
                || lowerReflection.contains("may be")
                || lowerReflection.contains("from what")
                || lowerReflection.contains("seems like")
                || lowerReflection.contains("might")
        )
        #expect(!turn.themeNotes.isEmpty)
        #expect(
            turn.recommendedTool == .focusBubble
                || turn.recommendedTool == .worryBox
                || turn.recommendedTool == .guidedBreathing
                || turn.recommendedTool == .softUnwind
        )
    }

    @Test func mockClosingSuggestsTwoOrThreePersonalizedActivities() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let history = [
            ChatMessage(role: .user, text: "I feel lonely and disappointed in myself"),
            ChatMessage(role: .assistant, text: "It sounds like something tender may be present."),
        ]
        let closing = try await client.reflectionClosing(history: history)

        #expect(!closing.summary.isEmpty)
        #expect(closing.invitationLine == ReflectionClosing.defaultInvitationLine)
        #expect(closing.suggestedActivities.count >= 2 && closing.suggestedActivities.count <= 3)
        #expect(
            closing.suggestedActivities.contains(.kindNote)
                || closing.suggestedActivities.contains(.bubbleDrift)
                || closing.suggestedActivities.contains(.softUnwind)
        )
    }

    @Test func mockAnalyzeStillSupportsCrisisAndFolders() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let crisis = try await client.analyze(
            transcript: "I want to die",
            availableFolderNames: ["School"],
            systemPrompt: ""
        )
        #expect(crisis.crisis)
        #expect(crisis.crisisKind == .selfHarm)

        let harmToOthers = try await client.analyze(
            transcript: "I want to attack him",
            availableFolderNames: ["School"],
            systemPrompt: ""
        )
        #expect(harmToOthers.crisis)
        #expect(harmToOthers.crisisKind == .harmToOthers)
        #expect(!harmToOthers.reflection.lowercased().contains("988"))

        let withFolder = try await client.analyze(
            transcript: "Stress about School and deadlines",
            availableFolderNames: ["School"],
            systemPrompt: ""
        )
        #expect(withFolder.suggestedFolder == "School")
        #expect(!withFolder.crisis)
        #expect(withFolder.crisisKind == .none)
    }

    @Test func harmToOthersTurnUsesDeEscalationLanguage() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let turn = try await client.reflectionTurn(
            for: "I want to kill them",
            history: []
        )
        #expect(turn.crisisKind == .harmToOthers)
        #expect(turn.crisis)
        let lower = turn.reflection.lowercased()
        #expect(!lower.contains("988"))
        #expect(lower.contains("intense feelings") || lower.contains("immediate"))
        #expect(lower.contains("distance") || lower.contains("trusted") || lower.contains("emergency"))
    }

    @Test func activitySuggestionsArePersonalizedByTheme() {
        let school = ActivitySuggestionHelper.suggestActivities(
            theme: .holdOneThing,
            lowerTranscript: "exams and deadline pressure"
        )
        #expect(school.contains(.focusBubble) || school.contains(.worryBox))
        #expect(school.count == 3)

        let lonely = ActivitySuggestionHelper.suggestActivities(
            theme: .playSoftly,
            lowerTranscript: "feeling lonely tonight"
        )
        #expect(lonely.first == .kindNote || lonely.contains(.kindNote))
    }

    @Test func placeholderThemeNotesAreReplacedOrHidden() {
        let replaced = ActivitySuggestionHelper.sanitizeThemeNotes(
            ["soft theme", "another soft theme"],
            userText: "I'm overwhelmed with exams and deadlines"
        )
        #expect(!replaced.isEmpty)
        #expect(!replaced.contains(where: { $0.lowercased().contains("soft theme") }))

        let hidden = ActivitySuggestionHelper.sanitizeThemeNotes(
            ["soft theme"],
            userText: ""
        )
        #expect(hidden.isEmpty)
    }

    @Test func doesNotInventSchoolContextWithoutMention() async throws {
        let result = ReflectionEngine.analyze(transcript: "I feel so overwhelmed right now")
        #expect(!result.hasExplicitContext)
        #expect(!result.reflection.lowercased().contains("school"))
        #expect(!result.reflection.lowercased().contains("work"))
        #expect(result.stressor == "unspecified")

        let notes = ActivitySuggestionHelper.themeNotes(from: result)
        #expect(!notes.contains(where: { $0.lowercased().contains("school") }))

        let client = MockLLMClient(simulatedDelay: .zero)
        let turn = try await client.reflectionTurn(
            for: "I feel so overwhelmed right now",
            history: []
        )
        #expect(!(turn.followUpQuestion?.lowercased().contains("school") ?? false))
        #expect(turn.followUpQuestion != nil)
    }

    @Test func namesSchoolOnlyWhenMentioned() {
        let result = ReflectionEngine.analyze(transcript: "I'm stressed about school exams")
        #expect(result.hasExplicitContext)
        #expect(result.stressor == "school")
        #expect(result.reflection.lowercased().contains("school"))
    }

    @Test func chatClientRouterAlwaysReturnsClient() {
        let routed = ChatClientRouter.makeClient()
        #expect(!routed.sourceLabel.isEmpty)
        #expect(
            routed.sourceLabel == "On-device Nest"
                || routed.sourceLabel == "Offline Nest assistant"
        )
    }

    @Test func continueTurnReceivesHistoryContext() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let history = [
            ChatMessage(role: .user, text: "School has been hard"),
            ChatMessage(role: .assistant, text: "It sounds like school may be weighing on you."),
        ]
        let turn = try await client.reflectionTurn(
            for: "And I'm also worried about my roommate",
            history: history
        )
        #expect(!turn.reflection.isEmpty)
        #expect(
            turn.reflection.contains("Continuing")
                || turn.reflection.contains("Thank you for sharing more")
                || turn.reflection.contains("adding to this")
                || turn.reflection.contains("sounds like")
        )
    }

    @Test func greetingDoesNotInferEmotionalState() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let turn = try await client.reflectionTurn(for: "hiii", history: [])

        let lowerReflection = turn.reflection.lowercased()
        #expect(!lowerReflection.contains("overwhelm"))
        #expect(!lowerReflection.contains("stressed"))
        #expect(!lowerReflection.contains("struggling"))
        #expect(!lowerReflection.contains("anxious"))
        #expect(!lowerReflection.contains("heavy"))
        #expect(turn.emotion == "unspecified")
        #expect(turn.themeNotes.isEmpty)
        #expect(turn.followUpQuestion != nil)
        #expect(!(turn.followUpQuestion?.lowercased().contains("contributing to this feeling") ?? false))
    }

    @Test func acknowledgementDoesNotInferEmotionalState() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let turn = try await client.reflectionTurn(for: "okay", history: [])

        let lowerReflection = turn.reflection.lowercased()
        #expect(!lowerReflection.contains("overwhelm"))
        #expect(!lowerReflection.contains("stressed"))
        #expect(!lowerReflection.contains("meaningful"))
        #expect(turn.emotion == "unspecified")
        #expect(turn.themeNotes.isEmpty)
    }

    @Test func neutralMessageDetectionCoversGreetingsAndAcknowledgements() {
        #expect(ReflectionEngine.isNeutralMessage(transcript: "hi"))
        #expect(ReflectionEngine.isNeutralMessage(transcript: "hello"))
        #expect(ReflectionEngine.isNeutralMessage(transcript: "hiii"))
        #expect(ReflectionEngine.isNeutralMessage(transcript: "thanks"))
        #expect(ReflectionEngine.isNeutralMessage(transcript: "sure"))
        #expect(!ReflectionEngine.isNeutralMessage(transcript: "I'm stressed about exams"))
        #expect(!ReflectionEngine.isNeutralMessage(transcript: "I feel sad and lonely"))
    }

    @Test func explicitEmotionStillReflectedWhenStated() async throws {
        let client = MockLLMClient(simulatedDelay: .zero)
        let turn = try await client.reflectionTurn(
            for: "I'm so stressed about exams",
            history: []
        )

        #expect(turn.emotion != "unspecified")
        #expect(!turn.reflection.isEmpty)
        #expect(turn.reflection.lowercased().contains("stress") || turn.reflection.lowercased().contains("exam"))
    }
}
