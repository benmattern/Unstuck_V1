import Foundation
import UserNotifications

enum NotificationManager {
    private static let dailyReminderIdentifier = "unstuck.dailyReminder"

    static func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleDailyReminder(at date: Date) async throws {
        cancelPendingUnstuckNotifications()

        let content = UNMutableNotificationContent()
        content.title = "Unstuck"
        content.body = "Time for a check-in."
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    static func cancelPendingUnstuckNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [dailyReminderIdentifier]
        )
    }
}
