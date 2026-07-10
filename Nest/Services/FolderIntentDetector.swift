import Foundation
import NaturalLanguage

/// AI-assisted folder detection from a spoken transcript.
enum FolderIntentDetector {
    struct DetectionResult {
        let folder: ThoughtFolder
        let cleanedText: String
        let confidence: Double
    }

    /// Detects which folder the user intended from the opening word(s) of a transcript.
    static func detect(in transcript: String, folders: [ThoughtFolder]) -> DetectionResult? {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let userFolders = folders.filter { !$0.isInbox }
        guard !userFolders.isEmpty else { return nil }

        var bestMatch: DetectionResult?

        for folder in userFolders {
            let candidates = [folder.keyword, folder.name.lowercased()].filter { !$0.isEmpty }

            for candidate in candidates {
                if let remainder = stripLeadingKeyword(candidate, from: trimmed) {
                    let result = DetectionResult(folder: folder, cleanedText: remainder, confidence: 1.0)
                    if bestMatch == nil || result.confidence > bestMatch!.confidence {
                        bestMatch = result
                    }
                }
            }
        }

        if bestMatch == nil, let firstWord = firstMeaningfulToken(in: trimmed) {
            for folder in userFolders {
                let candidates = [folder.keyword, folder.name.lowercased()]
                for candidate in candidates where !candidate.isEmpty {
                    let distance = levenshteinDistance(firstWord, candidate)
                    let maxDistance = candidate.count <= 4 ? 1 : 2
                    if distance <= maxDistance {
                        let remainder = removeFirstToken(from: trimmed)
                        let confidence = 1.0 - (Double(distance) * 0.2)
                        let result = DetectionResult(folder: folder, cleanedText: remainder, confidence: confidence)
                        if bestMatch == nil || confidence > bestMatch!.confidence {
                            bestMatch = result
                        }
                    }
                }
            }
        }

        return bestMatch
    }

    /// Routes a transcript to a folder using AI-assisted intent detection.
    static func route(transcript: String, folders: [ThoughtFolder]) -> (folder: ThoughtFolder, cleanedText: String) {
        let inbox = folders.first(where: \.isInbox) ?? folders.last!

        if let detected = detect(in: transcript, folders: folders) {
            let text = detected.cleanedText.isEmpty ? detected.folder.name : detected.cleanedText
            return (detected.folder, text)
        }

        return (inbox, transcript.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func stripLeadingKeyword(_ keyword: String, from text: String) -> String? {
        let lowerText = text.lowercased()
        let lowerKeyword = keyword.lowercased()
        guard lowerText.hasPrefix(lowerKeyword) else { return nil }

        let remainder = text.dropFirst(keyword.count)
        let cleaned = remainder.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return String(cleaned)
    }

    private static func firstMeaningfulToken(in text: String) -> String? {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var first: String?
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            first = String(text[range]).lowercased().trimmingCharacters(in: .punctuationCharacters)
            return false
        }
        return first?.isEmpty == false ? first : nil
    }

    private static func removeFirstToken(from text: String) -> String {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var started = false
        var remainder = ""

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            if !started {
                started = true
                return true
            }
            remainder += text[range]
            return true
        }

        return remainder.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        var distances = Array(0...right.count)

        for (leftIndex, leftChar) in left.enumerated() {
            var nextDistances = [leftIndex + 1]
            for (rightIndex, rightChar) in right.enumerated() {
                let cost = leftChar == rightChar ? 0 : 1
                let insertCost = nextDistances[rightIndex] + 1
                let deleteCost = distances[rightIndex + 1] + 1
                let replaceCost = distances[rightIndex] + cost
                nextDistances.append(min(insertCost, deleteCost, replaceCost))
            }
            distances = nextDistances
        }

        return distances[right.count]
    }
}
