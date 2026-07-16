import Foundation
import SwiftData

/// Date range presets for mood history on Personal.
enum MoodHistoryRange: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    /// Segmented-control title for this range.
    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        }
    }
}

/// Inserts and filters mood entries; migrates legacy UserDefaults check-ins.
enum MoodStore {
    private static let legacyMoodKey = "nest.mood.today.value"
    private static let legacyDateKey = "nest.mood.today.date"
    private static let migrationKey = "nest.migration.moodEntriesFromUserDefaults"

    /// Inserts a new mood check-in and saves the context.
    /// - Parameters:
    ///   - mood: The selected mood option.
    ///   - modelContext: SwiftData context to insert into.
    /// - Returns: The newly created entry.
    @discardableResult
    static func insert(
        _ mood: MoodOption,
        in modelContext: ModelContext
    ) -> MoodEntry {
        let existingEntries = (try? modelContext.fetch(FetchDescriptor<MoodEntry>())) ?? []
        let isFirstCheckInToday = todaysEntries(from: existingEntries).isEmpty

        let entry = MoodEntry(mood: mood)
        modelContext.insert(entry)
        do {
            try modelContext.save()
            if isFirstCheckInToday {
                XPStore.awardDailyCheckInIfNeeded()
            }
        } catch {
            print("MoodStore: failed to save mood entry — \(error.localizedDescription)")
        }
        return entry
    }

    /// Filters entries that fall on the current calendar day.
    /// - Parameters:
    ///   - entries: All mood entries to filter.
    ///   - calendar: Calendar used for day boundaries.
    ///   - now: Reference “now” for “today.”
    /// - Returns: Today’s entries sorted oldest → newest.
    static func todaysEntries(
        from entries: [MoodEntry],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [MoodEntry] {
        entries
            .filter { calendar.isDate($0.createdAt, inSameDayAs: now) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Latest mood option saved today, if any.
    /// - Parameters:
    ///   - entries: All mood entries to search.
    ///   - calendar: Calendar used for day boundaries.
    ///   - now: Reference “now” for “today.”
    /// - Returns: The most recent mood option for today.
    static func latestToday(
        from entries: [MoodEntry],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> MoodOption? {
        todaysEntries(from: entries, calendar: calendar, now: now)
            .last?
            .mood
    }

    /// Entries within the selected week or month window.
    /// - Parameters:
    ///   - entries: All mood entries to filter.
    ///   - range: Week or month preset.
    ///   - calendar: Calendar used for range boundaries.
    ///   - now: Reference end of the range.
    /// - Returns: Matching entries sorted newest → oldest.
    static func entries(
        from entries: [MoodEntry],
        in range: MoodHistoryRange,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [MoodEntry] {
        guard let start = rangeStart(for: range, calendar: calendar, now: now) else {
            return []
        }
        return entries
            .filter { $0.createdAt >= start && $0.createdAt <= now }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Groups entries by calendar day for history lists.
    /// - Parameters:
    ///   - entries: Entries already filtered to a range.
    ///   - calendar: Calendar used for day boundaries.
    /// - Returns: Day starts paired with that day’s entries (newest days first).
    static func groupedByDay(
        _ entries: [MoodEntry],
        calendar: Calendar = .current
    ) -> [(day: Date, entries: [MoodEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        return grouped
            .map { day, dayEntries in
                (
                    day: day,
                    entries: dayEntries.sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { $0.day > $1.day }
    }

    /// Migrates the old single-day UserDefaults mood into a MoodEntry once.
    /// - Parameter modelContext: SwiftData context to insert into.
    static func migrateLegacyUserDefaultsIfNeeded(in modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        defer {
            UserDefaults.standard.removeObject(forKey: legacyMoodKey)
            UserDefaults.standard.removeObject(forKey: legacyDateKey)
            UserDefaults.standard.set(true, forKey: migrationKey)
        }

        guard let rawValue = UserDefaults.standard.string(forKey: legacyMoodKey),
              let mood = MoodOption(rawValue: rawValue),
              let dateString = UserDefaults.standard.string(forKey: legacyDateKey) else {
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        let dayStart = formatter.date(from: dateString) ?? Date()
        let createdAt = calendarNoon(on: dayStart) ?? dayStart
        let entry = MoodEntry(mood: mood, createdAt: createdAt)
        modelContext.insert(entry)

        do {
            try modelContext.save()
        } catch {
            print("MoodStore: failed to migrate legacy mood — \(error.localizedDescription)")
        }
    }

    /// Start of the selected history window (inclusive).
    /// - Parameters:
    ///   - range: Week or month preset.
    ///   - calendar: Calendar used for date math.
    ///   - now: Reference date for the end of the window.
    /// - Returns: Inclusive start date for the range.
    private static func rangeStart(
        for range: MoodHistoryRange,
        calendar: Calendar,
        now: Date
    ) -> Date? {
        switch range {
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        case .month:
            return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))
        }
    }

    /// Noon on the given calendar day for a sensible migrated timestamp.
    private static func calendarNoon(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day)
    }
}
