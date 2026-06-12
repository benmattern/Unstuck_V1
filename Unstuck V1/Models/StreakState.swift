import Foundation

struct StreakState: Codable {
    let completedToday: Bool
    let currentStreak: Int
    let lastCompletedDate: Date?

    init(
        completedToday: Bool = false,
        currentStreak: Int = 0,
        lastCompletedDate: Date? = nil
    ) {
        self.completedToday = completedToday
        self.currentStreak = currentStreak
        self.lastCompletedDate = lastCompletedDate
    }
}
