import Foundation

/// Persists Nest XP and awards daily check-in XP at most once per calendar day.
enum XPStore {
    /// UserDefaults key for total XP; also used with `@AppStorage` on Personal.
    static let totalXPKey = "nest.xp.total"

    private static let lastAwardDayKey = "nest.xp.lastAwardDay"
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// XP granted for the first mood check-in of a calendar day.
    static let dailyCheckInXP = 25

    /// XP required to fill the profile progress bar (level-up UI comes later).
    static let xpToNextLevel = 100

    /// Total XP earned by the user, persisted between launches.
    static var totalXP: Int {
        get { UserDefaults.standard.integer(forKey: totalXPKey) }
        set { UserDefaults.standard.set(newValue, forKey: totalXPKey) }
    }

    /// Awards daily check-in XP if the user has not already been awarded today.
    /// - Parameters:
    ///   - calendar: Calendar used for day boundaries.
    ///   - now: Reference “now” for the calendar day.
    /// - Returns: `true` when XP was awarded; otherwise `false`.
    @discardableResult
    static func awardDailyCheckInIfNeeded(
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        let dayKey = dayFormatter.string(from: calendar.startOfDay(for: now))
        guard UserDefaults.standard.string(forKey: lastAwardDayKey) != dayKey else {
            return false
        }

        totalXP += dailyCheckInXP
        UserDefaults.standard.set(dayKey, forKey: lastAwardDayKey)
        return true
    }
}
