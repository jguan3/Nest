import SwiftUI

/// Lists mood entries for a day, showing the most recent three until expanded.
struct MoodEntryDayList: View {
    /// Entries for a single day (any order; newest are shown first).
    let entries: [MoodEntry]
    /// Visual density for Home (compact) vs Personal history (regular).
    var density: Density = .regular

    @State private var isExpanded = false
    @State private var expandedEntryIDs: Set<UUID> = []

    /// How many recent entries to show before requiring expand.
    static let previewLimit = 3

    enum Density {
        case compact
        case regular
    }

    private var newestFirst: [MoodEntry] {
        entries.sorted { $0.createdAt > $1.createdAt }
    }

    private var visibleEntries: [MoodEntry] {
        if isExpanded || newestFirst.count <= Self.previewLimit {
            return newestFirst
        }
        return Array(newestFirst.prefix(Self.previewLimit))
    }

    private var hiddenCount: Int {
        max(0, newestFirst.count - Self.previewLimit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(visibleEntries, id: \.id) { entry in
                if let mood = entry.mood {
                    entrySection(mood: mood, entry: entry)
                }
            }

            if newestFirst.count > Self.previewLimit {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "View \(hiddenCount) more")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NestTheme.primaryText.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isExpanded
                        ? "Show fewer mood check-ins"
                        : "View \(hiddenCount) more mood check-ins"
                )
            }
        }
    }

    /// A tappable mood row and its optional expanded details.
    /// - Parameters:
    ///   - mood: Resolved mood option for display.
    ///   - entry: Persisted entry providing time and journal content.
    @ViewBuilder
    private func entrySection(mood: MoodOption, entry: MoodEntry) -> some View {
        let isEntryExpanded = expandedEntryIDs.contains(entry.id)

        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if isEntryExpanded {
                        expandedEntryIDs.remove(entry.id)
                    } else {
                        expandedEntryIDs.insert(entry.id)
                    }
                }
            } label: {
                entryRow(mood: mood, entry: entry)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "\(mood.label) at \(entry.createdAt.formatted(date: .omitted, time: .shortened))"
            )
            .accessibilityValue(isEntryExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isEntryExpanded ? "Collapses check-in details" : "Expands check-in details")

            if isEntryExpanded {
                entryDetails(mood: mood, entry: entry)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// A single mood row with time.
    /// - Parameters:
    ///   - mood: Resolved mood option for display.
    ///   - entry: Persisted entry providing the timestamp.
    @ViewBuilder
    private func entryRow(mood: MoodOption, entry: MoodEntry) -> some View {
        HStack(spacing: density == .compact ? 10 : 12) {
            MoodSymbolView(
                mood: mood,
                font: density == .compact ? .caption : .body
            )
            .foregroundStyle(NestTheme.primaryText)
            .frame(width: density == .compact ? 18 : 22)

            Text(mood.label)
                .font(density == .compact ? .footnote.weight(.medium) : .body.weight(.medium))
                .foregroundStyle(NestTheme.primaryText)

            Spacer()

            Text(entry.createdAt, style: .time)
                .font(density == .compact ? .caption2 : .caption)
                .foregroundStyle(NestTheme.secondaryText)
        }
        .contentShape(Rectangle())
    }

    /// Expanded mood, time, and journal details for one check-in.
    /// - Parameters:
    ///   - mood: Resolved mood option for display.
    ///   - entry: Persisted entry providing time and journal content.
    @ViewBuilder
    private func entryDetails(mood: MoodOption, entry: MoodEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            detailLine(title: "Mood", value: mood.label)
            detailLine(
                title: "Time",
                value: entry.createdAt.formatted(date: .omitted, time: .shortened)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("Journal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestTheme.secondaryText)

                Text(journalDisplayText(for: entry))
                    .font(density == .compact ? .caption : .subheadline)
                    .foregroundStyle(NestTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(density == .compact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    /// A compact label and value row for expanded metadata.
    /// - Parameters:
    ///   - title: Metadata label.
    ///   - value: Metadata value.
    @ViewBuilder
    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            Text(value)
                .font(density == .compact ? .caption : .subheadline)
                .foregroundStyle(NestTheme.primaryText)
        }
    }

    /// Resolves journal content with a fallback for old or empty entries.
    /// - Parameter entry: Mood entry whose journal should be displayed.
    /// - Returns: Trimmed journal text or the empty-entry message.
    private func journalDisplayText(for entry: MoodEntry) -> String {
        MoodStore.normalizedJournalText(entry.journalText) ?? "No journal entry."
    }
}
