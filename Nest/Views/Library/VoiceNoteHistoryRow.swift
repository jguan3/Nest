import SwiftUI

/// Compact list row for a saved voice note in history.
struct VoiceNoteHistoryRow: View {
    let thought: Thought
    var onEditTitle: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(thought.displayTitle)
                    .font(.headline)
                    .foregroundStyle(NestTheme.primaryText)
                    .lineLimit(2)

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
        .accessibilityLabel("\(thought.displayTitle), \(thought.displayPreview), \(thought.createdAt.formatted(date: .abbreviated, time: .shortened))")
        .contextMenu {
            if let onEditTitle {
                Button("Edit Title") { onEditTitle() }
            }
        }
    }
}
