import Foundation

/// Structured AI reflection returned from a single analysis request.
struct ReflectionAnalysis: Codable, Equatable {
    let reflection: String
    let stressor: String
    let emotion: String
    let recommendedTool: CopingTool
    /// Name of a user-created folder, or nil when none fits.
    let suggestedFolder: String?
    /// Which safety interrupt applies, if any.
    let crisisKind: CrisisKind

    /// Whether this analysis should interrupt normal reflection.
    var crisis: Bool { crisisKind.interruptsReflection }

    private enum CodingKeys: String, CodingKey {
        case reflection, stressor, emotion, recommendedTool, suggestedFolder, crisisKind, crisis
    }

    /// Creates a structured reflection analysis.
    /// - Parameters:
    ///   - reflection: Soft-language reflection text.
    ///   - stressor: Situational label grounded in the transcript.
    ///   - emotion: Soft emotion/theme label.
    ///   - recommendedTool: Nest activity suggestion.
    ///   - suggestedFolder: Matching custom folder name, if any.
    ///   - crisisKind: Safety interrupt kind (defaults to none).
    init(
        reflection: String,
        stressor: String,
        emotion: String,
        recommendedTool: CopingTool,
        suggestedFolder: String?,
        crisisKind: CrisisKind = .none
    ) {
        self.reflection = reflection
        self.stressor = stressor
        self.emotion = emotion
        self.recommendedTool = recommendedTool
        self.suggestedFolder = suggestedFolder
        self.crisisKind = crisisKind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reflection = try container.decode(String.self, forKey: .reflection)
        stressor = try container.decode(String.self, forKey: .stressor)
        emotion = try container.decode(String.self, forKey: .emotion)
        recommendedTool = try container.decode(CopingTool.self, forKey: .recommendedTool)
        suggestedFolder = try container.decodeIfPresent(String.self, forKey: .suggestedFolder)
        if let kind = try container.decodeIfPresent(CrisisKind.self, forKey: .crisisKind) {
            crisisKind = kind
        } else if let legacyCrisis = try container.decodeIfPresent(Bool.self, forKey: .crisis), legacyCrisis {
            crisisKind = .selfHarm
        } else {
            crisisKind = .none
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reflection, forKey: .reflection)
        try container.encode(stressor, forKey: .stressor)
        try container.encode(emotion, forKey: .emotion)
        try container.encode(recommendedTool, forKey: .recommendedTool)
        try container.encodeIfPresent(suggestedFolder, forKey: .suggestedFolder)
        try container.encode(crisisKind, forKey: .crisisKind)
        try container.encode(crisis, forKey: .crisis)
    }
}
