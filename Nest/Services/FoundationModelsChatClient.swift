import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Primary conversational reflection client using Apple Foundation Models on-device.
final class FoundationModelsChatClient: ChatClient, @unchecked Sendable {
    #if canImport(FoundationModels)
    private let session: LanguageModelSession
    #endif

    /// Creates a Foundation Models chat client with Nest personality instructions.
    init() {
        #if canImport(FoundationModels)
        session = LanguageModelSession(
            instructions: Instructions(NestReflectionPersonality.instructions)
        )
        #endif
    }

    /// Preloads the on-device model when Reflection appears, if available.
    func prewarm() {
        #if canImport(FoundationModels)
        session.prewarm()
        #endif
    }

    /// Generates a reflection turn from the on-device model.
    /// - Parameters:
    ///   - userMessage: Final plain text for this turn.
    ///   - history: Prior session messages.
    /// - Returns: Parsed companion turn, or a local mock turn if parsing fails.
    func reflectionTurn(for userMessage: String, history: [ChatMessage]) async throws -> ReflectionTurn {
        #if canImport(FoundationModels)
        let isInitialTurn = history.isEmpty
        let promptText = Self.turnPrompt(userMessage: userMessage, history: history, isInitialTurn: isInitialTurn)
        let response = try await session.respond(to: Prompt(promptText))
        let content = String(describing: response.content)
        if let parsed = Self.parseTurn(from: content, userMessage: userMessage, isInitialTurn: isInitialTurn) {
            return parsed
        }
        return try await MockLLMClient(simulatedDelay: .zero).reflectionTurn(for: userMessage, history: history)
        #else
        return try await MockLLMClient(simulatedDelay: .zero).reflectionTurn(for: userMessage, history: history)
        #endif
    }

    /// Generates a closing summary and activity invitations.
    /// - Parameter history: Full session history.
    /// - Returns: Closing content with Nest CopingTool suggestions.
    func reflectionClosing(history: [ChatMessage]) async throws -> ReflectionClosing {
        #if canImport(FoundationModels)
        let promptText = Self.closingPrompt(history: history)
        let response = try await session.respond(to: Prompt(promptText))
        let content = String(describing: response.content)
        if let parsed = Self.parseClosing(from: content) {
            return parsed
        }
        return try await MockLLMClient(simulatedDelay: .zero).reflectionClosing(history: history)
        #else
        return try await MockLLMClient(simulatedDelay: .zero).reflectionClosing(history: history)
        #endif
    }

    // MARK: - Prompts

    private static func turnPrompt(userMessage: String, history: [ChatMessage], isInitialTurn: Bool) -> String {
        let historyBlock = history.isEmpty
            ? "(no earlier turns)"
            : history.map { "\($0.role.rawValue): \($0.text)" }.joined(separator: "\n")

        let titlePreviewFields = isInitialTurn
            ? """
,
          "title": "3-8 word summary of the main topic",
          "preview": "10-20 word summary of what they shared"
"""
            : ""

        let titlePreviewRules = isInitialTurn
            ? """
        - title: 3–8 words summarizing the main topic (not the first sentence copied).
        - preview: 10–20 words summarizing what they shared (not the first sentence copied).
        """
            : """
        - Do not include title or preview fields on follow-up turns.
        """

        return """
        Continue a Nest reflection conversation.

        Earlier turns:
        \(historyBlock)

        New user message:
        \(userMessage)

        Reply with JSON only (no markdown).

        Critical anti-hallucination rules:
        - Never invent causes, situations, or stressors the user did not mention.
        - Only set stressor / themeNotes mentioning school, work, family, friends, relationships, etc. if those words (or clear synonyms) appear in the user message.
        - If the cause is unclear, set stressor to null and ask a gentle clarifying followUpQuestion instead of guessing.
        - themeNotes: 0–3 short phrases grounded only in their words; use [] when nothing is clear.
        - Greetings ("hi", "hello", "hiii"), acknowledgements ("okay", "thanks", "sure"), and neutral messages
          must NOT receive emotional labels. Set emotion to null and themeNotes to [].
        - Never infer stress, anxiety, sadness, overwhelm, or struggle from neutral input.
        - For neutral messages, respond warmly without emotional interpretation
          (e.g. "Hiii! How are you doing today?", "Hey! What's on your mind?").
        - Only label emotions when the user explicitly states a feeling or describes a clearly emotional situation.
        - If unsure, ask an open-ended question ("Are you feeling…?", "Would you like to talk about…?")
          instead of stating emotions as facts.
        \(titlePreviewRules)

        Schema:
        {
          "reflection": "1-3 soft-language sentences grounded only in their words",
          "themeNotes": [],
          "followUpQuestion": "Is there something specific that's been contributing to this feeling?",
          "feelsNaturalPause": true,
          "crisis": false,
          "crisisKind": "none",
          "recommendedTool": "guidedBreathing",
          "stressor": null,
          "emotion": null\(titlePreviewFields)
        }

        Crisis kinds: "none" | "selfHarm" | "harmToOthers". Set crisis true only when crisisKind is not "none".
        For harmToOthers, do not recommend 988; follow Nest's harm-toward-others guidance instead.
        """
    }

    private static func closingPrompt(history: [ChatMessage]) -> String {
        let historyBlock = history.map { "\($0.role.rawValue): \($0.text)" }.joined(separator: "\n")
        return """
        The user is finished reflecting for now. Summarize gently and invite 2-3 Nest activities.

        Conversation:
        \(historyBlock)

        Reply with JSON only (no markdown):
        {
          "summary": "2 short soft-language sentences",
          "invitationLine": "Based on what you shared, here are a few things that might help:",
          "suggestedActivities": ["guidedBreathing", "worryBox", "kindNote"]
        }

        suggestedActivities must be 2 or 3 values from:
        guidedBreathing, softUnwind, colorGrounding, ripplePond, focusBubble, worryBox, bubbleDrift, kindNote
        Personalized to what they shared — invitations, not instructions.
        """
    }

    // MARK: - Parsing

    private struct TurnDTO: Decodable {
        let reflection: String
        let themeNotes: [String]?
        let followUpQuestion: String?
        let feelsNaturalPause: Bool?
        let crisis: Bool?
        let crisisKind: CrisisKind?
        let recommendedTool: String?
        let stressor: String?
        let emotion: String?
        let title: String?
        let preview: String?

        private enum CodingKeys: String, CodingKey {
            case reflection, themeNotes, followUpQuestion, feelsNaturalPause
            case crisis, crisisKind, recommendedTool, stressor, emotion, title, preview
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            reflection = try container.decode(String.self, forKey: .reflection)
            themeNotes = try container.decodeIfPresent([String].self, forKey: .themeNotes)
            followUpQuestion = try Self.decodeOptionalString(container, forKey: .followUpQuestion)
            feelsNaturalPause = try container.decodeIfPresent(Bool.self, forKey: .feelsNaturalPause)
            crisis = try container.decodeIfPresent(Bool.self, forKey: .crisis)
            crisisKind = try container.decodeIfPresent(CrisisKind.self, forKey: .crisisKind)
            recommendedTool = try Self.decodeOptionalString(container, forKey: .recommendedTool)
            stressor = try Self.decodeOptionalString(container, forKey: .stressor)
            emotion = try Self.decodeOptionalString(container, forKey: .emotion)
            title = try Self.decodeOptionalString(container, forKey: .title)
            preview = try Self.decodeOptionalString(container, forKey: .preview)
        }

        /// Resolves the interrupt kind from crisisKind, with legacy `crisis` bool fallback.
        /// - Returns: Mapped safety interrupt kind.
        var resolvedCrisisKind: CrisisKind {
            if let crisisKind, crisisKind != .none {
                return crisisKind
            }
            if crisis == true {
                return .selfHarm
            }
            return .none
        }

        private static func decodeOptionalString(
            _ container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> String? {
            if container.contains(key), try container.decodeNil(forKey: key) {
                return nil
            }
            return try container.decodeIfPresent(String.self, forKey: key)
        }
    }

    private struct ClosingDTO: Decodable {
        let summary: String
        let invitationLine: String?
        let suggestedActivities: [String]
    }

    private static func parseTurn(
        from content: String,
        userMessage: String,
        isInitialTurn: Bool
    ) -> ReflectionTurn? {
        guard let data = extractJSONData(from: content) else { return nil }
        guard let dto = try? JSONDecoder().decode(TurnDTO.self, from: data) else { return nil }
        // Drop model output that invents life contexts or emotions the user never named.
        if inventsUnstatedContext(in: dto.reflection, userText: userMessage)
            || inventsUnstatedEmotion(in: dto.reflection, userText: userMessage) {
            return nil
        }

        let tool = CopingTool(rawValue: dto.recommendedTool ?? "") ?? .softUnwind
        let lowerUser = userMessage.lowercased()
        let isNeutral = ReflectionEngine.isNeutralMessage(transcript: userMessage)
        let explicitContext = ReflectionEngine.explicitContextLabel(from: lowerUser)
        let emotion = isNeutral
            ? "unspecified"
            : (ReflectionEngine.explicitEmotionLabel(from: lowerUser) ?? "unspecified")
        let themeNotes = isNeutral
            ? []
            : ActivitySuggestionHelper.sanitizeThemeNotes(
                dto.themeNotes ?? [],
                userText: userMessage
            )
        var followUp = dto.followUpQuestion
        if isNeutral {
            followUp = ReflectionEngine.neutralFollowUpQuestion(seed: lowerUser)
        } else if explicitContext == nil {
            let clarifying = "Is there something specific that’s been contributing to this feeling?"
            if followUp == nil || followUp?.isEmpty == true
                || inventsUnstatedContext(in: followUp ?? "", userText: userMessage)
                || inventsUnstatedEmotion(in: followUp ?? "", userText: userMessage) {
                followUp = clarifying
            }
        }

        let summary: (title: String, preview: String)
        if isInitialTurn {
            let fallback = VoiceNoteSummaryHelper.summarize(transcript: userMessage)
            let parsedTitle = dto.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let parsedPreview = dto.preview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            summary = (
                title: parsedTitle.isEmpty ? fallback.title : parsedTitle,
                preview: parsedPreview.isEmpty ? fallback.preview : parsedPreview
            )
        } else {
            summary = (title: "", preview: "")
        }

        return ReflectionTurn(
            reflection: dto.reflection,
            themeNotes: themeNotes,
            followUpQuestion: followUp,
            feelsNaturalPause: dto.feelsNaturalPause ?? false,
            crisisKind: dto.resolvedCrisisKind,
            recommendedTool: tool,
            stressor: explicitContext ?? "unspecified",
            emotion: emotion,
            title: summary.title,
            preview: summary.preview
        )
    }

    /// Detects when generated text names school/work/family/etc. that the user never said.
    /// - Parameters:
    ///   - text: Model reflection or follow-up text.
    ///   - userText: Original user message.
    /// - Returns: True when the model invented an unstated situational context.
    private static func inventsUnstatedContext(in text: String, userText: String) -> Bool {
        let lowerText = text.lowercased()
        let lowerUser = userText.lowercased()
        let checks: [(needle: String, required: [String])] = [
            ("school", ["school", "exam", "finals", "class", "homework", "assignment", "lecture", "professor", "campus"]),
            ("exam", ["exam", "finals", "test"]),
            ("finals", ["exam", "finals", "test"]),
            ("homework", ["homework", "assignment"]),
            ("work", ["work", "job", "shift", "boss"]),
            ("job", ["work", "job", "shift", "boss"]),
            ("family", ["family", "mom", "dad", "parent", "sibling"]),
            ("roommate", ["roommate"]),
            ("relationship", ["relationship", "boyfriend", "girlfriend", "partner"]),
            ("boyfriend", ["boyfriend", "girlfriend", "partner", "relationship"]),
            ("girlfriend", ["boyfriend", "girlfriend", "partner", "relationship"]),
        ]

        for check in checks {
            guard lowerText.contains(check.needle) else { continue }
            let mentioned = check.required.contains { lowerUser.contains($0) }
            if !mentioned { return true }
        }

        // "friend(s)" is noisy because Nest copy can say "if a friend were…"; only flag
        // situational claims like "your friends" / "friendship" when user didn't mention them.
        if (lowerText.contains("your friend") || lowerText.contains("friendship") || lowerText.contains("friends"))
            && !(lowerUser.contains("friend") || lowerUser.contains("friends")) {
            return true
        }
        return false
    }

    /// Detects when generated text assigns emotions the user did not express.
    /// - Parameters:
    ///   - text: Model reflection or follow-up text.
    ///   - userText: Original user message.
    /// - Returns: True when the model invented an unstated emotional state.
    private static func inventsUnstatedEmotion(in text: String, userText: String) -> Bool {
        let lowerText = text.lowercased()
        let lowerUser = userText.lowercased()

        if ReflectionEngine.isNeutralMessage(transcript: userText) {
            let assumptionPhrases = [
                "overwhelm", "stressed", "anxious", "anxiety", "struggling", "struggle",
                "heavy", "hard to carry", "wearing on", "swirling", "piled up",
                "tender", "sad", "lonely", "distress", "worry", "worried",
                "you seem", "you're feeling", "you are feeling", "sounds like you're",
                "might be noticing", "may be noticing", "difficult time", "hard time",
                "contributing to this feeling", "something meaningful", "carries weight",
                "needed space", "showing up for yourself", "mix of things",
            ]
            return assumptionPhrases.contains { lowerText.contains($0) }
        }

        let emotionWords = [
            "overwhelm", "overwhelmed", "stressed", "anxious", "anxiety",
            "sad", "lonely", "struggling", "distress", "depressed", "depression",
            "panic", "worried", "worrying", "tension", "tense", "exhausted",
        ]
        for word in emotionWords where lowerText.contains(word) && !lowerUser.contains(word) {
            if word == "overwhelm", lowerUser.contains("too much") { continue }
            if word == "overwhelmed", lowerUser.contains("too much") { continue }
            if word == "worried", lowerUser.contains("worry") { continue }
            if word == "worrying", lowerUser.contains("worry") { continue }
            if word == "tense", lowerUser.contains("tension") { continue }
            return true
        }
        return false
    }

    private static func parseClosing(from content: String) -> ReflectionClosing? {
        guard let data = extractJSONData(from: content) else { return nil }
        guard let dto = try? JSONDecoder().decode(ClosingDTO.self, from: data) else { return nil }
        let tools = dto.suggestedActivities.compactMap { CopingTool(rawValue: $0) }
        guard tools.count >= 2 else { return nil }
        return ReflectionClosing(
            summary: dto.summary,
            invitationLine: dto.invitationLine ?? ReflectionClosing.defaultInvitationLine,
            suggestedActivities: Array(tools.prefix(3))
        )
    }

    private static func extractJSONData(from content: String) -> Data? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }
        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}") else { return nil }
        let slice = trimmed[start...end]
        return String(slice).data(using: .utf8)
    }
}
