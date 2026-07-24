import Foundation

/// Local reflection client used for Voice analysis and as ChatClient fallback.
struct MockLLMClient: LLMClient, ChatClient {
    var simulatedDelay: Duration = .seconds(1)

    /// Analyzes a transcript into a structured ReflectionAnalysis for Library persistence.
    /// - Parameters:
    ///   - transcript: User voice or text content.
    ///   - availableFolderNames: Custom folder names Nest may suggest.
    ///   - systemPrompt: Prompt from ReflectionPromptBuilder (unused by mock heuristics).
    /// - Returns: Structured analysis including crisis flag when triggered.
    func analyze(
        transcript: String,
        availableFolderNames: [String],
        systemPrompt: String
    ) async throws -> ReflectionAnalysis {
        try await Task.sleep(for: simulatedDelay)

        let turn = try await reflectionTurn(for: transcript, history: [])
        if turn.crisis {
            return ReflectionAnalysis(
                reflection: turn.reflection,
                stressor: turn.stressor,
                emotion: turn.emotion,
                recommendedTool: turn.recommendedTool,
                suggestedFolder: nil,
                crisisKind: turn.crisisKind
            )
        }

        let lower = transcript.lowercased()
        let matchedFolder = availableFolderNames.first { folderName in
            lower.contains(folderName.lowercased())
        }

        return ReflectionAnalysis(
            reflection: turn.reflection,
            stressor: turn.stressor,
            emotion: turn.emotion,
            recommendedTool: turn.recommendedTool,
            suggestedFolder: matchedFolder,
            crisisKind: .none
        )
    }

    /// Builds a conversational reflection turn with soft language and optional follow-up.
    /// - Parameters:
    ///   - userMessage: Final plain text for this turn.
    ///   - history: Prior session messages for light context awareness.
    /// - Returns: Companion turn suitable for the Reflection UI.
    func reflectionTurn(for userMessage: String, history: [ChatMessage]) async throws -> ReflectionTurn {
        try await Task.sleep(for: simulatedDelay)

        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        let summary = history.isEmpty
            ? VoiceNoteSummaryHelper.summarize(transcript: trimmed)
            : (title: "", preview: "")

        if let crisisKind = detectedCrisisKind(in: lower) {
            return ReflectionTurn(
                reflection: crisisReflection(for: crisisKind),
                themeNotes: ["needing support"],
                followUpQuestion: nil,
                feelsNaturalPause: true,
                crisisKind: crisisKind,
                recommendedTool: .guidedBreathing,
                stressor: "crisis",
                emotion: "distress",
                title: summary.title,
                preview: summary.preview
            )
        }

        let engine = ReflectionEngine.analyze(transcript: trimmed)
        let isNeutral = ReflectionEngine.isNeutralMessage(transcript: trimmed)
        let softEmotion = NestReflectionPersonality.softEmotionLabel(from: engine.emotion)
        let themeNotes = isNeutral
            ? []
            : ActivitySuggestionHelper.sanitizeThemeNotes(
                ActivitySuggestionHelper.themeNotes(from: engine),
                userText: trimmed
            )
        let followUp = isNeutral
            ? ReflectionEngine.neutralFollowUpQuestion(seed: lower)
            : followUpQuestion(
                for: engine.theme,
                explicitContext: engine.hasExplicitContext ? engine.stressor : nil,
                historyCount: history.count,
                seed: lower
            )

        let reflection = contextualizeReflection(
            base: engine.reflection,
            history: history,
            softEmotion: softEmotion,
            isNeutral: isNeutral
        )

        return ReflectionTurn(
            reflection: reflection,
            themeNotes: themeNotes,
            followUpQuestion: followUp,
            feelsNaturalPause: history.count >= 2 || followUp == nil,
            crisisKind: .none,
            recommendedTool: engine.recommendedTool,
            stressor: engine.stressor,
            emotion: softEmotion,
            title: summary.title,
            preview: summary.preview
        )
    }

    /// Builds a closing summary and personalized Nest activity invitations.
    /// - Parameter history: Full conversation history for the session.
    /// - Returns: Closing content with 2–3 optional CopingTool choices.
    func reflectionClosing(history: [ChatMessage]) async throws -> ReflectionClosing {
        try await Task.sleep(for: .milliseconds(350))

        let userText = history
            .filter { $0.role == .user }
            .map(\.text)
            .joined(separator: " ")
        let lower = userText.lowercased()
        let engine = ReflectionEngine.analyze(transcript: userText)
        let activities = ActivitySuggestionHelper.suggestActivities(
            theme: engine.theme,
            lowerTranscript: lower
        )

        let summary = closingSummary(userText: userText, engine: engine, turnCount: history.filter { $0.role == .user }.count)

        return ReflectionClosing(
            summary: summary,
            invitationLine: ReflectionClosing.defaultInvitationLine,
            suggestedActivities: activities
        )
    }

    // MARK: - Private helpers

    /// Detects self-harm or harm-to-others language in a lowercased message.
    /// - Parameter lower: Lowercased user text.
    /// - Returns: Matching crisis kind, or nil when no interrupt is needed.
    private func detectedCrisisKind(in lower: String) -> CrisisKind? {
        if containsSelfHarmLanguage(lower) {
            return .selfHarm
        }
        if containsHarmToOthersLanguage(lower) {
            return .harmToOthers
        }
        return nil
    }

    private func containsSelfHarmLanguage(_ lower: String) -> Bool {
        lower.contains("crisis")
            || lower.contains("kill myself")
            || lower.contains("hurt myself")
            || lower.contains("harm myself")
            || lower.contains("want to die")
            || lower.contains("suicide")
            || lower.contains("end my life")
            || lower.contains("suicidal")
    }

    private func containsHarmToOthersLanguage(_ lower: String) -> Bool {
        // Keep self-directed phrases on the self-harm path even if wording overlaps.
        if lower.contains("myself") || lower.contains("my life") {
            return false
        }

        let phrases = [
            "kill him", "kill her", "kill them", "kill someone",
            "hurt him", "hurt her", "hurt them", "hurt someone",
            "attack him", "attack her", "attack them", "attack someone",
            "harm him", "harm her", "harm them", "harm someone",
            "injure him", "injure her", "injure them", "injure someone",
            "want to kill", "want to hurt", "want to attack", "want to harm",
            "going to kill", "going to hurt", "going to attack",
            "hurt people", "kill people", "violent toward",
        ]
        return phrases.contains { lower.contains($0) }
    }

    /// Builds the interrupt reflection message for a given crisis kind.
    /// - Parameter kind: Self-harm or harm-to-others interrupt.
    /// - Returns: Supportive copy aligned with Nest's safety rules.
    private func crisisReflection(for kind: CrisisKind) -> String {
        switch kind {
        case .selfHarm:
            return "Thank you for sharing something so heavy. You deserve real support right now — please reach out to people and resources who can help keep you safe."
        case .harmToOthers:
            return "I’m sorry you’re dealing with such intense feelings right now. Are you in immediate danger of acting on these thoughts? If you can, create some distance from the person, place, or situation tied to this urge, and try a brief pause — slow breathing, stepping outside, drinking water, washing your face with cold water, or a short walk. Reach out to someone you trust who can help you stay safe. If these thoughts keep returning or feel hard to control, please seek support from a mental health professional soon. If you may act right away or can’t keep others safe, leave the situation if you can and contact local emergency services (such as 911) now."
        case .none:
            return ""
        }
    }

    private func followUpQuestion(
        for theme: ReflectionEngine.Theme,
        explicitContext: String?,
        historyCount: Int,
        seed: String
    ) -> String? {
        // First share often gets a gentle question; later turns pause more often.
        if historyCount >= 2 { return nil }

        // If cause/situation is unclear, prefer a clarifying question over guessing.
        if explicitContext == nil {
            let clarifying = [
                "Is there something specific that’s been contributing to this feeling?",
                "Would it help to name what’s been sitting underneath this, if anything?",
                "Is there a particular situation tied to this, or does it feel more general right now?",
            ]
            return clarifying[abs(seed.hashValue) % clarifying.count]
        }

        if abs(seed.hashValue) % 5 == 0 { return nil }

        let context = explicitContext ?? ""
        let options: [String]
        switch theme {
        case .calmTheBody:
            options = [
                "Is there one part of how this feels in your body that stands out most right now?",
                "Would it help to name what tends to settle you, even a little?",
            ]
        case .comeBackToNow:
            options = [
                "What feels most true about this moment, separate from the what-ifs?",
                "Is there one thought that keeps looping that you'd like to set down for a minute?",
            ]
        case .holdOneThing:
            options = [
                "If you could hold just one piece of \(context) today, which would it be?",
                "What would “good enough for today” look like with what you shared about \(context)?",
            ]
        case .playSoftly:
            options = [
                "What kind of kindness would feel supportive if a friend were in your shoes?",
                "Is there a small comfort that has helped you before, even briefly?",
            ]
        case .general:
            options = [
                "What feels most important about what you just shared?",
                "Is there anything else you want Nest to sit with you about?",
            ]
        }
        return options[abs(seed.hashValue) % options.count]
    }

    private func contextualizeReflection(
        base: String,
        history: [ChatMessage],
        softEmotion: String,
        isNeutral: Bool
    ) -> String {
        guard history.contains(where: { $0.role == .user }) else { return base }

        if isNeutral {
            let bridges = [
                "Got it. \(base)",
                "Thanks for letting me know. \(base)",
                "I'm still here with you. \(base)",
            ]
            let index = abs((softEmotion + base).hashValue) % bridges.count
            return bridges[index]
        }

        let bridges = [
            "Continuing from what you shared earlier, \(base.prefix(1).lowercased())\(base.dropFirst())",
            "Thank you for sharing more. \(base)",
            "I hear you adding to this. \(base)",
        ]
        let index = abs((softEmotion + base).hashValue) % bridges.count
        return String(bridges[index])
    }

    private func closingSummary(
        userText: String,
        engine: ReflectionEngine.AnalysisResult,
        turnCount: Int
    ) -> String {
        let softEmotion = NestReflectionPersonality.softEmotionLabel(from: engine.emotion)
        let hasEmotion = softEmotion != "unspecified" && softEmotion != "uncertainty"
        if ReflectionEngine.isNeutralMessage(transcript: userText) {
            return "Thanks for checking in with Nest. Whenever you're ready, I'm here."
        }
        if userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Thanks for checking in with Nest. Even a brief pause can be a gentle way to care for yourself."
        }

        if engine.hasExplicitContext {
            if turnCount > 1 {
                if hasEmotion {
                    return "It sounds like \(engine.stressor) has been part of what you’ve been sitting with, and you may be noticing \(softEmotion). Thank you for trusting Nest with it."
                }
                return "It sounds like \(engine.stressor) has been part of what you’ve been sitting with. Thank you for trusting Nest with it."
            }
            if hasEmotion {
                return "From what you shared, it seems like \(engine.stressor) has been on your mind, and you might be noticing \(softEmotion). You showed up for yourself by naming it."
            }
            return "From what you shared, it seems like \(engine.stressor) has been on your mind. You showed up for yourself by naming it."
        }

        if hasEmotion {
            return "From what you shared, you might be noticing \(softEmotion). Thank you for making space for that — you don’t have to have every detail named for it to matter."
        }
        return "Thank you for sharing what you did. You don’t have to explain the whole story for Nest to sit with you."
    }
}
