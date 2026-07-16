import Foundation

/// Detects emotional themes and generates personalized reflections for voice notes.
enum ReflectionEngine {
    enum Theme: CaseIterable {
        case calmTheBody
        case comeBackToNow
        case holdOneThing
        case playSoftly
        case general
    }

    struct AnalysisResult {
        let reflection: String
        /// Explicit situational context only (school, work, etc.), or a neutral marker when none was named.
        let stressor: String
        /// Soft emotion label grounded in words they used, or a neutral marker when none was named.
        let emotion: String
        let recommendedTool: CopingTool
        let theme: Theme
        /// True when school/work/relationships/etc. were explicitly mentioned.
        let hasExplicitContext: Bool
    }

    /// Returns whether the message is a greeting, acknowledgement, or other neutral input without emotional context.
    /// - Parameter transcript: Voice or typed user text.
    /// - Returns: True when the message should not receive emotional inference.
    static func isNeutralMessage(transcript: String) -> Bool {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        let lower = trimmed.lowercased()
        let stripped = lower.trimmingCharacters(in: .punctuationCharacters)

        if greetingPhrases.contains(stripped) { return true }
        if acknowledgementPhrases.contains(stripped) { return true }
        if matchesGreetingPattern(stripped) { return true }

        let wordCount = stripped.split(whereSeparator: \.isWhitespace).count
        if wordCount <= 3,
           explicitEmotionLabel(from: lower) == nil,
           explicitContextLabel(from: lower) == nil,
           !containsEmotionalSignal(in: lower) {
            return true
        }

        return false
    }

    /// Picks a warm, non-assumptive reflection for greetings and neutral messages.
    /// - Parameter seed: Lowercased user text used to vary phrasing.
    /// - Returns: Conversational reply without inferred emotional states.
    static func neutralReflection(seed: String) -> String {
        pickVariant(from: neutralReflections, seed: seed)
    }

    /// Picks a gentle open-ended follow-up for greetings and neutral messages.
    /// - Parameter seed: Lowercased user text used to vary phrasing.
    /// - Returns: Question that does not assume an emotional state.
    static func neutralFollowUpQuestion(seed: String) -> String {
        pickVariant(from: neutralFollowUps, seed: seed)
    }

    /// Analyzes a transcript into a reflection, theme, and tool suggestion without inventing unstated context.
    /// - Parameter transcript: Voice or typed reflection text.
    /// - Returns: Grounded analysis for Nest’s companion UI.
    static func analyze(transcript: String) -> AnalysisResult {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if isNeutralMessage(transcript: trimmed) {
            return AnalysisResult(
                reflection: neutralReflection(seed: lower),
                stressor: "unspecified",
                emotion: "unspecified",
                recommendedTool: .softUnwind,
                theme: .general,
                hasExplicitContext: false
            )
        }

        if trimmed.isEmpty {
            return AnalysisResult(
                reflection: pickVariant(from: emptyReflections, seed: lower),
                stressor: "unspecified",
                emotion: "unspecified",
                recommendedTool: .softUnwind,
                theme: .general,
                hasExplicitContext: false
            )
        }

        let scores = scoreThemes(in: lower)
        let theme = scores.max(by: { $0.value < $1.value })?.key ?? .general
        let tool = recommendTool(for: theme, in: lower)
        let explicitContext = explicitContextLabel(from: lower)
        let emotion = explicitEmotionLabel(from: lower)
        let reflection = buildReflection(
            transcript: trimmed,
            lower: lower,
            theme: theme,
            explicitContext: explicitContext,
            emotion: emotion
        )

        return AnalysisResult(
            reflection: reflection,
            stressor: explicitContext ?? "unspecified",
            emotion: emotion ?? "unspecified",
            recommendedTool: tool,
            theme: theme,
            hasExplicitContext: explicitContext != nil
        )
    }

    // MARK: - Theme Scoring

    private static func scoreThemes(in lower: String) -> [Theme: Int] {
        var scores: [Theme: Int] = [
            .calmTheBody: 0,
            .comeBackToNow: 0,
            .holdOneThing: 0,
            .playSoftly: 0,
            .general: 1,
        ]

        let calmKeywords = ["anxious", "anxiety", "stress", "stressed", "panic", "overwhelm", "overwhelmed", "tension", "tense", "tight", "racing heart", "can't breathe", "on edge"]
        let presentKeywords = ["overthink", "overthinking", "spiral", "spiraling", "future", "what if", "mind won't stop", "can't stop thinking", "present", "ground", "distracted", "everywhere"]
        let focusKeywords = ["school", "work", "class", "exam", "finals", "deadline", "project", "responsibilit", "scattered", "procrastinat", "focus", "focusing", "too much", "don't know where to start", "to-do", "assignment", "job"]
        let comfortKeywords = ["sad", "lonely", "alone", "critic", "hate myself", "disappoint", "hurt", "miss", "crying", "empty", "worthless", "not good enough", "comfort"]

        for word in calmKeywords where lower.contains(word) { scores[.calmTheBody, default: 0] += 2 }
        for word in presentKeywords where lower.contains(word) { scores[.comeBackToNow, default: 0] += 2 }
        for word in focusKeywords where lower.contains(word) { scores[.holdOneThing, default: 0] += 2 }
        for word in comfortKeywords where lower.contains(word) { scores[.playSoftly, default: 0] += 2 }

        return scores
    }

    // MARK: - Tool Recommendation

    private static func recommendTool(for theme: Theme, in lower: String) -> CopingTool {
        switch theme {
        case .calmTheBody:
            if lower.contains("panic") || lower.contains("racing") || lower.contains("anxious") || lower.contains("anxiety") {
                return .guidedBreathing
            }
            return lower.contains("tension") || lower.contains("tense") || lower.contains("tired") ? .softUnwind : .guidedBreathing

        case .comeBackToNow:
            if lower.contains("spiral") || lower.contains("overthink") || lower.contains("future") || lower.contains("what if") {
                return .colorGrounding
            }
            return .ripplePond

        case .holdOneThing:
            if lower.contains("worry") || lower.contains("scattered") || lower.contains("too much") || lower.contains("overwhelm") {
                return .worryBox
            }
            return .focusBubble

        case .playSoftly:
            if lower.contains("critic") || lower.contains("hate myself") || lower.contains("not good enough") || lower.contains("worthless") {
                return .kindNote
            }
            return lower.contains("sad") || lower.contains("lonely") || lower.contains("disappoint") ? .kindNote : .bubbleDrift

        case .general:
            return .softUnwind
        }
    }

    // MARK: - Neutral message detection

    private static let greetingPhrases: Set<String> = [
        "hi", "hey", "hello", "hiya", "howdy", "yo", "sup",
        "hi there", "hey there", "hello there",
        "good morning", "good afternoon", "good evening", "good night",
    ]

    private static let acknowledgementPhrases: Set<String> = [
        "ok", "okay", "k", "thanks", "thank you", "thx", "ty",
        "sure", "yeah", "yep", "yup", "nah", "nope",
        "got it", "alright", "right", "cool", "nice", "fine",
        "sounds good", "will do", "understood", "mhm", "mmhm", "mmhmm",
    ]

    private static func matchesGreetingPattern(_ stripped: String) -> Bool {
        let pattern = #"^(hi+|hey+|hello+)[!.?~:\s]*$"#
        return stripped.range(of: pattern, options: .regularExpression) != nil
    }

    private static func containsEmotionalSignal(in lower: String) -> Bool {
        let signals = [
            "stress", "stressed", "anxious", "anxiety", "sad", "angry", "mad",
            "overwhelm", "overwhelmed", "worried", "worry", "scared", "afraid",
            "lonely", "alone", "tired", "exhaust", "hurt", "crying", "cry",
            "panic", "depress", "frustrat", "upset", "disappoint", "nervous",
            "tense", "struggling", "struggle", "hard time", "rough day", "bad day",
            "can't cope", "hate myself", "want to die", "kill myself",
        ]
        return signals.contains { lower.contains($0) }
    }

    private static let neutralReflections = [
        "Hiii! How are you doing today?",
        "Hey! What's on your mind?",
        "Hi :) How can I support you right now?",
        "Hello! I'm glad you checked in — what's going on for you?",
        "Hey there — I'm here whenever you're ready to share.",
    ]

    private static let neutralFollowUps = [
        "What's on your mind today?",
        "Is there anything you'd like to talk through?",
        "Would you like to share what's been on your mind lately?",
        "What would feel helpful to talk about right now?",
    ]

    // MARK: - Explicit context & emotion (no invented causes)

    /// Returns a situational label only when the user clearly named that context.
    /// - Parameter lower: Lowercased transcript.
    /// - Returns: Explicit context label, or nil when none was named.
    static func explicitContextLabel(from lower: String) -> String? {
        if lower.contains("exam") || lower.contains("finals") || lower.contains("class")
            || lower.contains("school") || lower.contains("homework") || lower.contains("assignment")
            || lower.contains("lecture") || lower.contains("professor") || lower.contains("campus") {
            return "school"
        }
        if lower.contains("work") || lower.contains("job") || lower.contains("shift") || lower.contains("boss") {
            return "work"
        }
        if lower.contains("roommate") {
            return "roommates"
        }
        if lower.contains("family") || lower.contains("mom") || lower.contains("dad")
            || lower.contains("parent") || lower.contains("sibling") {
            return "family"
        }
        if lower.contains("relationship") || lower.contains("boyfriend") || lower.contains("girlfriend")
            || lower.contains("partner") || lower.contains("friend") {
            return "relationships"
        }
        if lower.contains("what if") || (lower.contains("future") && (lower.contains("worry") || lower.contains("scared") || lower.contains("anxious") || lower.contains("stress"))) {
            return "the future"
        }
        return nil
    }

    /// Returns a soft emotion label only when feeling-words appear in the transcript.
    /// - Parameter lower: Lowercased transcript.
    /// - Returns: Soft emotion phrase, or nil when none was named.
    static func explicitEmotionLabel(from lower: String) -> String? {
        if lower.contains("anxious") || lower.contains("anxiety") { return "possible anxiety" }
        if lower.contains("sad") || lower.contains("lonely") || lower.contains("alone") { return "a heavier mood" }
        if lower.contains("overwhelm") || lower.contains("overwhelmed") { return "a sense of overwhelm" }
        if lower.contains("stress") || lower.contains("stressed") { return "possible stress" }
        if lower.contains("tired") || lower.contains("exhaust") { return "possible tiredness" }
        if lower.contains("scared") || lower.contains("afraid") { return "possible unease" }
        if lower.contains("tension") || lower.contains("tense") { return "possible tension" }
        if lower.contains("disappoint") { return "possible disappointment" }
        return nil
    }

    // MARK: - Reflection Copy

    private static func buildReflection(
        transcript: String,
        lower: String,
        theme: Theme,
        explicitContext: String?,
        emotion: String?
    ) -> String {
        let snippet = meaningfulSnippet(from: transcript)
        let seed = lower + snippet
        let templates = reflectionTemplates(
            for: theme,
            snippet: snippet,
            explicitContext: explicitContext,
            emotion: emotion
        )
        return pickVariant(from: templates, seed: seed)
    }

    private static func meaningfulSnippet(from transcript: String) -> String {
        let cleaned = transcript
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)

        guard !cleaned.isEmpty else { return "what you shared" }

        let words = cleaned.split(whereSeparator: \.isWhitespace)
        if words.count <= 6 { return cleaned }

        let prefix = words.prefix(8).joined(separator: " ")
        return "\"\(prefix)…\""
    }

    private static func reflectionTemplates(
        for theme: Theme,
        snippet: String,
        explicitContext: String?,
        emotion: String?
    ) -> [String] {
        let feelingPhrase = emotion.map { " You may be noticing \($0)." } ?? ""

        if let context = explicitContext {
            return [
                "From what you shared about \(snippet), it sounds like \(context) has been weighing on you.\(feelingPhrase)",
                "It seems like \(context) is showing up in what you shared about \(snippet).\(feelingPhrase)",
                "What you said about \(snippet) suggests \(context) has been on your mind.\(feelingPhrase)",
            ]
        }

        // No named context — stay with their words; never invent a cause.
        switch theme {
        case .calmTheBody:
            return [
                "From what you shared about \(snippet), it sounds like this has been hard to carry in your body.\(feelingPhrase)",
                "It seems like what you named around \(snippet) has been wearing on you.\(feelingPhrase)",
                "What you said about \(snippet) sounds heavy right now.\(feelingPhrase)",
            ]
        case .comeBackToNow:
            return [
                "From what you shared about \(snippet), it sounds like your thoughts may be swirling.\(feelingPhrase)",
                "It seems like \(snippet) has been hard to set down in your mind.\(feelingPhrase)",
                "What you said about \(snippet) suggests a lot may be circling at once.\(feelingPhrase)",
            ]
        case .holdOneThing:
            return [
                "From what you shared about \(snippet), it seems like a lot may be asking for your attention.\(feelingPhrase)",
                "It sounds like \(snippet) left you without a clear place to start.\(feelingPhrase)",
                "What you said about \(snippet) suggests things may feel piled up right now.\(feelingPhrase)",
            ]
        case .playSoftly:
            return [
                "From what you shared about \(snippet), it sounds like something tender is present.\(feelingPhrase)",
                "It seems like \(snippet) may need a little gentleness.\(feelingPhrase)",
                "What you said about \(snippet) sounds like comfort could matter more than answers right now.\(feelingPhrase)",
            ]
        case .general:
            return [
                "From what you shared about \(snippet), it sounds like something meaningful is on your mind.\(feelingPhrase)",
                "It sounds like you needed space to say \(snippet) out loud.\(feelingPhrase)",
                "What you shared about \(snippet) carries weight — and that's worth honoring.\(feelingPhrase)",
            ]
        }
    }

    private static let emptyReflections = [
        "It sounds like you needed a quiet moment to check in. However you're feeling right now is worth honoring.",
        "From what I heard, you showed up for yourself just by pausing. That alone is something gentle and brave.",
        "You may be feeling a mix of things you haven't named yet — and that's okay. This moment is yours.",
    ]

    private static func pickVariant(from options: [String], seed: String) -> String {
        let index = abs(seed.hashValue) % options.count
        return options[index]
    }
}
