import Combine
import Foundation
import Supabase

@MainActor
final class NotificationScheduleStore: ObservableObject {
    @Published var schedules: [NotificationSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSchedules(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: PostgrestResponse<[NotificationSchedule]> = try await supabase
                .from("notification_schedules")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()

            schedules = response.value
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load notification schedules."
            print("Supabase notification schedule load failed: \(error)")
        }
    }

    func createSchedule(
        userId: UUID,
        title: String,
        isEnabled: Bool,
        scheduleType: NotificationScheduleType,
        scheduledAt: Date?,
        scheduledTime: String?,
        formType: NotificationScheduleFormType
    ) async {
        isLoading = true
        defer { isLoading = false }

        let payload = NotificationScheduleInsert(
            user_id: userId,
            title: title,
            is_enabled: isEnabled,
            schedule_type: scheduleType.rawValue,
            scheduled_at: scheduledAt,
            scheduled_time: scheduledTime,
            form_type: formType.rawValue,
            updated_at: Date()
        )

        do {
            let response: PostgrestResponse<NotificationSchedule> = try await supabase
                .from("notification_schedules")
                .insert(payload)
                .select()
                .single()
                .execute()

            schedules.insert(response.value, at: 0)
            errorMessage = nil

            if response.value.isEnabled {
                try await NotificationManager.scheduleNotification(for: response.value)
            }
        } catch {
            errorMessage = "Unable to create notification schedule."
            print("Supabase notification schedule create failed: \(error)")
        }
    }

    func updateScheduleEnabled(_ schedule: NotificationSchedule, isEnabled: Bool) async {
        isLoading = true
        defer { isLoading = false }

        let payload = NotificationScheduleEnabledUpdate(
            is_enabled: isEnabled,
            updated_at: Date()
        )

        do {
            let response: PostgrestResponse<NotificationSchedule> = try await supabase
                .from("notification_schedules")
                .update(payload)
                .eq("id", value: schedule.id.uuidString)
                .select()
                .single()
                .execute()

            replaceSchedule(response.value)
            errorMessage = nil

            if response.value.isEnabled {
                try await NotificationManager.scheduleNotification(for: response.value)
            } else {
                NotificationManager.cancelNotification(identifier: response.value.id.uuidString)
            }
        } catch {
            errorMessage = "Unable to update notification schedule."
            print("Supabase notification schedule update failed: \(error)")
        }
    }

    func deleteSchedule(_ schedule: NotificationSchedule) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase
                .from("notification_schedules")
                .delete()
                .eq("id", value: schedule.id.uuidString)
                .execute()

            schedules.removeAll { $0.id == schedule.id }
            NotificationManager.cancelNotification(identifier: schedule.id.uuidString)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to delete notification schedule."
            print("Supabase notification schedule delete failed: \(error)")
        }
    }

    func clear() {
        schedules = []
        isLoading = false
        errorMessage = nil
    }

    private func replaceSchedule(_ schedule: NotificationSchedule) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else {
            schedules.insert(schedule, at: 0)
            return
        }

        schedules[index] = schedule
    }
}

private struct NotificationScheduleInsert: Encodable {
    let user_id: UUID
    let title: String
    let is_enabled: Bool
    let schedule_type: String
    let scheduled_at: Date?
    let scheduled_time: String?
    let form_type: String
    let updated_at: Date
}

private struct NotificationScheduleEnabledUpdate: Encodable {
    let is_enabled: Bool
    let updated_at: Date
}
