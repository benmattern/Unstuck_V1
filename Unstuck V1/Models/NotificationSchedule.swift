import Foundation

enum NotificationScheduleType: String, Codable, CaseIterable, Identifiable {
    case oneTime = "one_time"
    case daily

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .oneTime:
            "One-Time"
        case .daily:
            "Daily"
        }
    }
}

enum NotificationScheduleFormType: String, Codable, CaseIterable, Identifiable {
    case shortCheckIn = "short_check_in"
    case mainForm = "main_form"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .shortCheckIn:
            "Short Check-In"
        case .mainForm:
            "Main Form"
        }
    }
}

struct NotificationSchedule: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var isEnabled: Bool
    var scheduleType: NotificationScheduleType
    var scheduledAt: Date?
    var scheduledTime: String?
    var formType: NotificationScheduleFormType
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case isEnabled = "is_enabled"
        case scheduleType = "schedule_type"
        case scheduledAt = "scheduled_at"
        case scheduledTime = "scheduled_time"
        case formType = "form_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
