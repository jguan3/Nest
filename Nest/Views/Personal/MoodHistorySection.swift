import SwiftUI

/// Week / month list of mood check-ins for the Personal tab.
struct MoodHistorySection: View {
    let moodEntries: [MoodEntry]

    @State private var selectedRange: MoodHistoryRange = .week

    private var filteredEntries: [MoodEntry] {
        MoodStore.entries(from: moodEntries, in: selectedRange)
    }

    private var groupedDays: [(day: Date, entries: [MoodEntry])] {
        MoodStore.groupedByDay(filteredEntries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood history")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            Picker("Range", selection: $selectedRange) {
                ForEach(MoodHistoryRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Mood history range")

            if groupedDays.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(groupedDays, id: \.day) { group in
                        dayGroup(day: group.day, entries: group.entries)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
    }

    private var emptyMessage: String {
        switch selectedRange {
        case .week:
            "No check-ins yet this week."
        case .month:
            "No check-ins yet this month."
        }
    }

    /// Renders one calendar day’s mood entries (newest three, then expand).
    /// - Parameters:
    ///   - day: Start of the calendar day.
    ///   - entries: Mood entries recorded that day.
    @ViewBuilder
    private func dayGroup(day: Date, entries: [MoodEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            MoodEntryDayList(entries: entries, density: .regular)
        }
    }
}
