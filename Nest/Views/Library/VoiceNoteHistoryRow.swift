import SwiftUI

/// Compact list row for a saved voice note in history.
struct VoiceNoteHistoryRow: View {
    let thought: Thought
    var onEditTitle: (() -> Void)?
    var onToggleOvercome: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(thought.displayTitle)
                    .font(.headline)
                    .foregroundStyle(NestTheme.primaryText)
                    .lineLimit(2)

                if thought.isOvercome {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 0.65))
                        .accessibilityLabel("Overcome")
                }

                Spacer(minLength: 8)

                Text(thought.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(NestTheme.secondaryText)
            }

            Text(thought.displayPreview)
                .font(.subheadline)
                .foregroundStyle(NestTheme.secondaryText)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .contextMenu {
            if let onEditTitle {
                Button("Edit Title") { onEditTitle() }
            }
            if let onToggleOvercome {
                Button(thought.isOvercome ? "Unmark overcome" : "Mark as overcome") {
                    onToggleOvercome()
                }
            }
        }
    }

    private var accessibilitySummary: String {
        var parts = [
            thought.displayTitle,
            thought.displayPreview,
            thought.createdAt.formatted(date: .abbreviated, time: .shortened)
        ]
        if thought.isOvercome {
            parts.append("Marked as overcome")
        }
        return parts.joined(separator: ", ")
    }
}
