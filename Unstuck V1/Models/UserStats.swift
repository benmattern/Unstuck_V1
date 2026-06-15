import Foundation

struct UserStats: Codable {
    let userId: UUID
    let currentStreak: Int
    let completedToday: Bool
    let lastCheckInAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentStreak = "current_streak"
        case completedToday = "completed_today"
        case lastCheckInAt = "last_check_in_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
