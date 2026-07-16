import SwiftUI

/// Lists mood entries for a day, showing the most recent three until expanded.
struct MoodEntryDayList: View {
    /// Entries for a single day (any order; newest are shown first).
    let entries: [MoodEntry]
    /// Visual density for Home (compact) vs Personal history (regular).
    var density: Density = .regular

    @State private var isExpanded = false

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
                    entryRow(mood: mood, entry: entry)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(mood.label) at \(entry.createdAt.formatted(date: .omitted, time: .shortened))"
        )
    }
}
