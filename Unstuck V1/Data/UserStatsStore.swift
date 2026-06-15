import Combine
import Foundation
import Supabase

@MainActor
final class UserStatsStore: ObservableObject {
    @Published var currentStreak = 0
    @Published var completedToday = false
    @Published var lastCheckInAt: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func loadStats(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: PostgrestResponse<[UserStats]> = try await supabase
                .from("user_stats")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()

            guard let stats = response.value.first else {
                applyDefaults()
                errorMessage = nil
                return
            }

            apply(stats)
            errorMessage = nil
        } catch {
            applyDefaults()
            errorMessage = "Unable to load progress."
            print("Supabase user stats load failed: \(error)")
        }
    }

    func recordCompletion(userId: UUID) async {
        let completionDate = Date()
        let nextStreak: Int

        if let lastCheckInAt,
           calendar.isDate(lastCheckInAt, inSameDayAs: completionDate) {
            nextStreak = currentStreak
        } else if let lastCheckInAt,
                  isYesterday(lastCheckInAt, relativeTo: completionDate) {
            nextStreak = currentStreak + 1
        } else {
            nextStreak = 1
        }

        await saveStats(
            userId: userId,
            currentStreak: nextStreak,
            completedToday: true,
            lastCheckInAt: completionDate
        )
    }

    func resetStats(userId: UUID) async {
        await saveStats(
            userId: userId,
            currentStreak: 0,
            completedToday: false,
            lastCheckInAt: nil
        )
    }

    func clear() {
        applyDefaults()
        isLoading = false
        errorMessage = nil
    }

    private func saveStats(
        userId: UUID,
        currentStreak: Int,
        completedToday: Bool,
        lastCheckInAt: Date?
    ) async {
        isLoading = true
        defer { isLoading = false }

        let payload = UserStatsUpsert(
            user_id: userId,
            current_streak: currentStreak,
            completed_today: completedToday,
            last_check_in_at: lastCheckInAt,
            updated_at: Date()
        )

        do {
            let response: PostgrestResponse<UserStats> = try await supabase
                .from("user_stats")
                .upsert(payload, onConflict: "user_id")
                .select()
                .single()
                .execute()

            apply(response.value)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to save progress."
            print("Supabase user stats save failed: \(error)")
        }
    }

    private func apply(_ stats: UserStats) {
        currentStreak = stats.currentStreak
        lastCheckInAt = stats.lastCheckInAt
        completedToday = stats.lastCheckInAt.map {
            calendar.isDateInToday($0)
        } ?? stats.completedToday
    }

    private func applyDefaults() {
        currentStreak = 0
        completedToday = false
        lastCheckInAt = nil
    }

    private func isYesterday(_ date: Date, relativeTo currentDate: Date) -> Bool {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
            return false
        }

        return calendar.isDate(date, inSameDayAs: yesterday)
    }
}

private struct UserStatsUpsert: Encodable {
    let user_id: UUID
    let current_streak: Int
    let completed_today: Bool
    let last_check_in_at: Date?
    let updated_at: Date
}
