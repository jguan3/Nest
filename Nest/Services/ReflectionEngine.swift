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
        let stressor: String
        let emotion: String
        let recommendedTool: CopingTool
        let theme: Theme
    }

    static func analyze(transcript: String) -> AnalysisResult {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if trimmed.isEmpty {
            return AnalysisResult(
                reflection: pickVariant(from: emptyReflections, seed: lower),
                stressor: "checking in",
                emotion: "quiet moment",
                recommendedTool: .softUnwind,
                theme: .general
            )
        }

        let scores = scoreThemes(in: lower)
        let theme = scores.max(by: { $0.value < $1.value })?.key ?? .general
        let tool = recommendTool(for: theme, in: lower)
        let stressor = inferStressor(from: lower, theme: theme)
        let emotion = inferEmotion(from: lower, theme: theme)
        let reflection = buildReflection(
            transcript: trimmed,
            lower: lower,
            theme: theme,
            stressor: stressor,
            emotion: emotion
        )

        return AnalysisResult(
            reflection: reflection,
            stressor: stressor,
            emotion: emotion,
            recommendedTool: tool,
            theme: theme
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

    // MARK: - Reflection Copy

    private static func buildReflection(
        transcript: String,
        lower: String,
        theme: Theme,
        stressor: String,
        emotion: String
    ) -> String {
        let snippet = meaningfulSnippet(from: transcript)
        let seed = lower + snippet
        let templates = reflectionTemplates(for: theme, snippet: snippet, stressor: stressor, emotion: emotion)
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
        stressor: String,
        emotion: String
    ) -> [String] {
        switch theme {
        case .calmTheBody:
            return [
                "From what you shared about \(snippet), it sounds like your body has been holding a lot of \(emotion). That kind of weight is real, and it makes sense you'd feel stretched thin.",
                "It sounds like \(stressor) has your nerves running high right now. You may be feeling \(emotion) — and that's a natural response to what you're carrying.",
                "What you said about \(snippet) tells me this has been physically and emotionally demanding. You don't have to push through it alone.",
                "You may be feeling \(emotion) after everything around \(stressor). Even naming it out loud, the way you did, is a gentle act of care.",
            ]

        case .comeBackToNow:
            return [
                "It sounds like your mind has been pulling you toward \(stressor), and staying present feels harder than usual. From what you shared, there's a lot circling at once.",
                "What you said about \(snippet) suggests your thoughts may be spiraling a bit. You may be feeling \(emotion) — and that's understandable when the future feels loud.",
                "From what you shared, it sounds like you're caught between worries that haven't happened yet and feelings that are here right now. That takes a lot of energy.",
                "You may be feeling \(emotion) as your mind replays and rehearses. It sounds like you're looking for a little stillness amid the noise.",
            ]

        case .holdOneThing:
            return [
                "It sounds like \(stressor) is asking more of you than you have room for right now. You may be feeling \(emotion) — especially when everything needs attention at once.",
                "From what you shared about \(snippet), it seems like you're juggling a lot without a clear place to start. That scattered feeling is more common than it feels.",
                "What you said about \(snippet) sounds like responsibility has been piling up. You may be feeling \(emotion), and it makes sense when the list keeps growing.",
                "It sounds like focus has been hard to find with \(stressor) on your plate. You don't have to solve everything at once to deserve a pause.",
            ]

        case .playSoftly:
            return [
                "From what you shared about \(snippet), it sounds like something tender is hurting underneath. You may be feeling \(emotion) — and that's worth being gentle with.",
                "It sounds like \(stressor) has left you feeling \(emotion). The way you named it suggests you're carrying more softness than you're giving yourself credit for.",
                "What you said about \(snippet) tells me you might need comfort more than answers right now. You deserve kindness, especially from yourself.",
                "You may be feeling \(emotion) after what you shared. It sounds like a small, low-pressure moment of care could meet you where you are.",
            ]

        case .general:
            return [
                "From what you shared about \(snippet), it sounds like something meaningful is on your mind. You may be feeling \(emotion) — and that's worth honoring.",
                "It sounds like you needed space to say \(snippet) out loud. Whatever you're feeling right now doesn't need to be fixed to be valid.",
                "What you shared about \(snippet) carries more weight than a few words might suggest. You may be feeling \(emotion), and that makes sense.",
                "You may be feeling \(emotion) after sharing \(snippet). It sounds like simply naming it was a brave, honest step.",
            ]
        }
    }

    private static let emptyReflections = [
        "It sounds like you needed a quiet moment to check in. However you're feeling right now is worth honoring.",
        "From what I heard, you showed up for yourself just by pausing. That alone is something gentle and brave.",
        "You may be feeling a mix of things you haven't named yet — and that's okay. This moment is yours.",
    ]

    private static func inferStressor(from lower: String, theme: Theme) -> String {
        if lower.contains("exam") || lower.contains("finals") || lower.contains("class") { return "school" }
        if lower.contains("work") || lower.contains("job") { return "work" }
        if lower.contains("relationship") || lower.contains("friend") || lower.contains("family") { return "relationships" }
        if lower.contains("future") || lower.contains("what if") { return "the future" }
        switch theme {
        case .calmTheBody: return "pressure"
        case .comeBackToNow: return "racing thoughts"
        case .holdOneThing: return "responsibilities"
        case .playSoftly: return "emotional pain"
        case .general: return "daily life"
        }
    }

    private static func inferEmotion(from lower: String, theme: Theme) -> String {
        if lower.contains("anxious") || lower.contains("anxiety") { return "anxiety" }
        if lower.contains("sad") || lower.contains("lonely") { return "sadness" }
        if lower.contains("stress") || lower.contains("overwhelm") { return "overwhelm" }
        if lower.contains("tired") || lower.contains("exhaust") { return "exhaustion" }
        if lower.contains("scared") || lower.contains("afraid") { return "fear" }
        switch theme {
        case .calmTheBody: return "tension"
        case .comeBackToNow: return "restlessness"
        case .holdOneThing: return "scattered focus"
        case .playSoftly: return "hurt"
        case .general: return "uncertainty"
        }
    }

    private static func pickVariant(from options: [String], seed: String) -> String {
        let index = abs(seed.hashValue) % options.count
        return options[index]
    }
}
