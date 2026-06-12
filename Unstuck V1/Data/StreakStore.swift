import Combine
import Foundation

final class StreakStore: ObservableObject {
    @Published var state: StreakState

    private let calendar: Calendar
    private let userDefaults: UserDefaults
    private var currentUserId: UUID?

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        self.state = StreakState()
    }

    func configureForUser(userId: UUID?) {
        currentUserId = userId

        guard let userId else {
            state = StreakState()
            return
        }

        state = Self.loadState(from: userDefaults, key: streakKey(for: userId))
        refreshTodayStatus()
    }

    func recordCompletion(on date: Date = Date()) {
        if let lastCompletedDate = state.lastCompletedDate,
           calendar.isDate(lastCompletedDate, inSameDayAs: date) {
            state = StreakState(
                completedToday: true,
                currentStreak: state.currentStreak,
                lastCompletedDate: date
            )
            persistState()
            return
        }

        let nextStreak: Int

        if let lastCompletedDate = state.lastCompletedDate {
            nextStreak = isYesterday(lastCompletedDate, relativeTo: date)
                ? state.currentStreak + 1
                : 1
        } else {
            nextStreak = 1
        }

        state = StreakState(
            completedToday: true,
            currentStreak: nextStreak,
            lastCompletedDate: date
        )
        persistState()
    }

    func reset() {
        state = StreakState()
        persistState()
    }

    func refreshTodayStatus() {
        let completedToday = state.lastCompletedDate.map {
            calendar.isDateInToday($0)
        } ?? false

        state = StreakState(
            completedToday: completedToday,
            currentStreak: state.currentStreak,
            lastCompletedDate: state.lastCompletedDate
        )
        persistState()
    }

    private func isYesterday(_ date: Date, relativeTo currentDate: Date) -> Bool {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
            return false
        }

        return calendar.isDate(date, inSameDayAs: yesterday)
    }

    private func persistState() {
        guard let currentUserId else {
            return
        }

        do {
            let data = try JSONEncoder().encode(state)
            userDefaults.set(data, forKey: streakKey(for: currentUserId))
        } catch {
            print("Failed to save streak state: \(error)")
        }
    }

    private func streakKey(for userId: UUID) -> String {
        "streakState_\(userId.uuidString)"
    }

    private static func loadState(from userDefaults: UserDefaults, key: String) -> StreakState {
        guard let data = userDefaults.data(forKey: key) else {
            return StreakState()
        }

        do {
            return try JSONDecoder().decode(StreakState.self, from: data)
        } catch {
            print("Failed to load streak state: \(error)")
            return StreakState()
        }
    }
}
