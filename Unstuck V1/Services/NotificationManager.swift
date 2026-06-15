import Foundation
import UserNotifications

enum NotificationManager {
    static func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleNotification(for schedule: NotificationSchedule) async throws {
        _ = try await requestPermission()
        cancelNotification(identifier: schedule.id.uuidString)

        let content = UNMutableNotificationContent()
        content.title = schedule.title
        content.body = "Time for a \(schedule.formType.displayName)."
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch schedule.scheduleType {
        case .oneTime:
            guard let scheduledAt = schedule.scheduledAt else {
                return
            }

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: scheduledAt
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .daily:
            guard let scheduledTime = schedule.scheduledTime,
                  let components = dateComponents(fromScheduledTime: scheduledTime) else {
                return
            }

            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: schedule.id.uuidString,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    static func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    private static func dateComponents(fromScheduledTime scheduledTime: String) -> DateComponents? {
        let parts = scheduledTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else {
            return nil
        }

        var components = DateComponents()
        components.hour = parts[0]
        components.minute = parts[1]
        return components
    }
}
