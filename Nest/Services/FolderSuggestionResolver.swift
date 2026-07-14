import Foundation

/// Maps an AI-suggested folder name to an existing user-created ThoughtFolder.
enum FolderSuggestionResolver {
    /// Resolves a suggested folder name to an existing folder, or Inbox when no match.
    static func resolve(
        suggestedFolder: String?,
        folders: [ThoughtFolder]
    ) -> ThoughtFolder {
        let inbox = folders.first(where: \.isInbox) ?? folders.last!
        let userFolders = folders.filter { !$0.isInbox }

        guard let suggested = suggestedFolder?.trimmingCharacters(in: .whitespacesAndNewlines),
              !suggested.isEmpty else {
            return inbox
        }

        let lowerSuggested = suggested.lowercased()

        if let exact = userFolders.first(where: { $0.name.lowercased() == lowerSuggested }) {
            return exact
        }

        var bestFolder: ThoughtFolder?
        var bestDistance = Int.max

        for folder in userFolders {
            let distance = levenshteinDistance(lowerSuggested, folder.name.lowercased())
            if distance <= 2, distance < bestDistance {
                bestDistance = distance
                bestFolder = folder
            }
        }

        return bestFolder ?? inbox
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
