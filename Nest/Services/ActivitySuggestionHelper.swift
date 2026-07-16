import Foundation

/// Builds personalized Nest activity invitations from reflection theme signals.
enum ActivitySuggestionHelper {
    /// Suggests two or three CopingTools matched to the user’s situation.
    /// - Parameters:
    ///   - theme: Primary reflection theme from local analysis.
    ///   - lowerTranscript: Lowercased combined user text for keyword cues.
    /// - Returns: Two or three distinct Nest activities as optional choices.
    static func suggestActivities(
        theme: ReflectionEngine.Theme,
        lowerTranscript: String
    ) -> [CopingTool] {
        var tools: [CopingTool] = []

        switch theme {
        case .calmTheBody:
            tools = [.guidedBreathing, .softUnwind, .ripplePond]
        case .comeBackToNow:
            tools = [.colorGrounding, .ripplePond, .softUnwind]
        case .holdOneThing:
            if lowerTranscript.contains("worry") || lowerTranscript.contains("overwhelm") {
                tools = [.worryBox, .focusBubble, .guidedBreathing]
            } else {
                tools = [.focusBubble, .worryBox, .colorGrounding]
            }
        case .playSoftly:
            tools = [.kindNote, .bubbleDrift, .softUnwind]
        case .general:
            tools = [.softUnwind, .guidedBreathing, .kindNote]
        }

        if lowerTranscript.contains("lonely") || lowerTranscript.contains("alone") {
            tools = prioritize(inserting: .kindNote, into: tools)
        }
        if lowerTranscript.contains("school") || lowerTranscript.contains("exam") || lowerTranscript.contains("deadline") {
            tools = prioritize(inserting: .focusBubble, into: tools)
        }

        return Array(tools.prefix(3))
    }

    /// Maps an engine analysis into soft theme notes for the UI.
    /// - Parameter result: Engine analysis for the latest user text.
    /// - Returns: Zero to three soft notes grounded only in what they explicitly named.
    static func themeNotes(from result: ReflectionEngine.AnalysisResult) -> [String] {
        var notes: [String] = []
        let softEmotion = NestReflectionPersonality.softEmotionLabel(from: result.emotion)

        if isMeaningfulEmotion(softEmotion) {
            notes.append(softEmotion)
        }

        // Only surface situational themes when the user named that context.
        if result.hasExplicitContext, isMeaningfulStressor(result.stressor) {
            notes.append("pressure around \(result.stressor)")
        }

        return Array(notes.prefix(3))
    }

    /// Cleans model-provided theme notes and falls back to local analysis when needed.
    /// - Parameters:
    ///   - notes: Theme notes from the AI client.
    ///   - userText: Latest user message for fallback extraction.
    /// - Returns: Meaningful theme notes, or an empty array when none can be found.
    static func sanitizeThemeNotes(_ notes: [String], userText: String) -> [String] {
        let lowerUser = userText.lowercased()
        let cleaned = notes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !isPlaceholderThemeNote($0) }
            .filter { isThemeNoteGrounded($0, in: lowerUser) || lowerUser.isEmpty }

        if !cleaned.isEmpty {
            // When we have user text, keep only notes that don't invent unstated contexts.
            if lowerUser.isEmpty {
                return Array(cleaned.filter { !isPlaceholderThemeNote($0) }.prefix(3))
            }
            return Array(cleaned.prefix(3))
        }

        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return themeNotes(from: ReflectionEngine.analyze(transcript: trimmed))
    }

    /// Rejects theme notes that claim school/work/family/etc. when the user never said those words.
    /// - Parameters:
    ///   - note: Candidate theme note.
    ///   - lowerUser: Lowercased user text (empty skips context grounding).
    /// - Returns: Whether the note is safe to show.
    private static func isThemeNoteGrounded(_ note: String, in lowerUser: String) -> Bool {
        guard !lowerUser.isEmpty else { return true }
        let lowerNote = note.lowercased()
        let contextTokens: [(token: String, requiresAnyOf: [String])] = [
            ("school", ["school", "exam", "finals", "class", "homework", "assignment", "lecture", "professor", "campus"]),
            ("exam", ["exam", "finals", "test"]),
            ("work", ["work", "job", "shift", "boss"]),
            ("job", ["work", "job", "shift", "boss"]),
            ("family", ["family", "mom", "dad", "parent", "sibling"]),
            ("friend", ["friend", "friends"]),
            ("relationship", ["relationship", "boyfriend", "girlfriend", "partner", "friend"]),
            ("roommate", ["roommate"]),
            ("future", ["future", "what if"]),
        ]

        for entry in contextTokens {
            if lowerNote.contains(entry.token) {
                let mentioned = entry.requiresAnyOf.contains { lowerUser.contains($0) }
                if !mentioned { return false }
            }
        }
        return true
    }

    private static func isPlaceholderThemeNote(_ note: String) -> Bool {
        let lower = note.lowercased()
        let placeholders = [
            "soft theme",
            "another soft theme",
            "soft theme label",
            "brief soft theme",
            "brief situational label",
            "theme note",
            "example theme",
            "theme 1",
            "theme 2",
        ]
        if placeholders.contains(where: { lower == $0 || lower.contains($0) }) {
            return true
        }
        return lower.hasPrefix("optional") || lower == "null" || lower == "none"
    }

    private static func isMeaningfulEmotion(_ emotion: String) -> Bool {
        let lower = emotion.lowercased()
        return lower != "uncertainty"
            && lower != "quiet moment"
            && lower != "unknown"
            && lower != "unspecified"
            && !lower.contains("soft theme")
    }

    private static func isMeaningfulStressor(_ stressor: String) -> Bool {
        let lower = stressor.lowercased()
        return lower != "daily life"
            && lower != "checking in"
            && lower != "unknown"
            && lower != "unspecified"
            && !lower.contains("situational label")
    }

    private static func prioritize(inserting tool: CopingTool, into tools: [CopingTool]) -> [CopingTool] {
        var next = tools.filter { $0 != tool }
        next.insert(tool, at: 0)
        return Array(next.prefix(3))
    }
}
