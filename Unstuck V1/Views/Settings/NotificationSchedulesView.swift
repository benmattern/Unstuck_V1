import Supabase
import SwiftUI

struct NotificationSchedulesView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var notificationScheduleStore: NotificationScheduleStore
    @State private var title = ""
    @State private var scheduleType: NotificationScheduleType = .daily
    @State private var formType: NotificationScheduleFormType = .shortCheckIn
    @State private var oneTimeDate = Date().addingTimeInterval(3600)
    @State private var dailyTime = Self.defaultDailyTime
    @State private var isEnabled = true
    @State private var statusMessage: String?

    private static var defaultDailyTime: Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                SectionHeader("Notification Schedules", subtitle: "Create reminders tied to a form.")
                createScheduleCard
                schedulesSection

                if let statusMessage {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Schedules")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: authService.currentUser?.id) {
            await loadSchedules()
        }
        .refreshable {
            await loadSchedules()
        }
    }

    private var createScheduleCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("New Reminder")
                    .font(.headline)

                TextField("Title", text: $title)
                    .textInputAutocapitalization(.words)
                    .padding(AppTheme.Spacing.medium)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))

                Picker("Schedule", selection: $scheduleType) {
                    ForEach(NotificationScheduleType.allCases) { type in
                        Text(type.displayName)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Form", selection: $formType) {
                    ForEach(NotificationScheduleFormType.allCases) { type in
                        Text(type.displayName)
                            .tag(type)
                    }
                }

                if scheduleType == .oneTime {
                    DatePicker(
                        "Date and Time",
                        selection: $oneTimeDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } else {
                    DatePicker(
                        "Time",
                        selection: $dailyTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                Toggle("Enabled", isOn: $isEnabled)

                Button {
                    createSchedule()
                } label: {
                    PrimaryButton("Save Schedule", systemImage: "bell.badge")
                }
                .buttonStyle(.plain)
                .disabled(notificationScheduleStore.isLoading)
            }
        }
    }

    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Saved Schedules", subtitle: "Manage reminders stored in Supabase.")

            if notificationScheduleStore.schedules.isEmpty {
                AppCard {
                    Text("No notification schedules yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(notificationScheduleStore.schedules) { schedule in
                        scheduleRow(schedule)
                    }
                }
            }

            if let errorMessage = notificationScheduleStore.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func scheduleRow(_ schedule: NotificationSchedule) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(schedule.title)
                            .font(.headline)

                        Text(schedule.formType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(scheduleDescription(schedule))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Toggle(
                        "Enabled",
                        isOn: Binding(
                            get: { schedule.isEnabled },
                            set: { newValue in
                                updateSchedule(schedule, isEnabled: newValue)
                            }
                        )
                    )
                    .labelsHidden()
                }

                Button(role: .destructive) {
                    deleteSchedule(schedule)
                } label: {
                    SecondaryButton("Delete Schedule", systemImage: "trash")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadSchedules() async {
        guard let userId = authService.currentUser?.id else {
            notificationScheduleStore.clear()
            return
        }

        await notificationScheduleStore.loadSchedules(userId: userId)
    }

    private func createSchedule() {
        guard let userId = authService.currentUser?.id else {
            statusMessage = "Sign in is required to create schedules."
            return
        }

        let scheduleTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Unstuck Reminder"
            : title.trimmingCharacters(in: .whitespacesAndNewlines)
        let scheduledAt = scheduleType == .oneTime ? oneTimeDate : nil
        let scheduledTime = scheduleType == .daily ? timeString(from: dailyTime) : nil

        Task {
            await notificationScheduleStore.createSchedule(
                userId: userId,
                title: scheduleTitle,
                isEnabled: isEnabled,
                scheduleType: scheduleType,
                scheduledAt: scheduledAt,
                scheduledTime: scheduledTime,
                formType: formType
            )

            await MainActor.run {
                statusMessage = notificationScheduleStore.errorMessage ?? "Notification schedule saved."
                title = ""
                isEnabled = true
            }
        }
    }

    private func updateSchedule(_ schedule: NotificationSchedule, isEnabled: Bool) {
        Task {
            await notificationScheduleStore.updateScheduleEnabled(schedule, isEnabled: isEnabled)
            await MainActor.run {
                statusMessage = notificationScheduleStore.errorMessage ?? "Notification schedule updated."
            }
        }
    }

    private func deleteSchedule(_ schedule: NotificationSchedule) {
        Task {
            await notificationScheduleStore.deleteSchedule(schedule)
            await MainActor.run {
                statusMessage = notificationScheduleStore.errorMessage ?? "Notification schedule deleted."
            }
        }
    }

    private func scheduleDescription(_ schedule: NotificationSchedule) -> String {
        switch schedule.scheduleType {
        case .oneTime:
            guard let scheduledAt = schedule.scheduledAt else {
                return "One-time reminder"
            }

            return "One-time: \(scheduledAt.formatted(date: .abbreviated, time: .shortened))"
        case .daily:
            return "Daily: \(displayTime(from: schedule.scheduledTime))"
        }
    }

    private func timeString(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d:00", components.hour ?? 0, components.minute ?? 0)
    }

    private func displayTime(from scheduledTime: String?) -> String {
        guard let scheduledTime else {
            return "No time set"
        }

        let parts = scheduledTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else {
            return scheduledTime
        }

        var components = DateComponents()
        components.hour = parts[0]
        components.minute = parts[1]

        guard let date = Calendar.current.date(from: components) else {
            return scheduledTime
        }

        return date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    NavigationStack {
        NotificationSchedulesView()
            .environmentObject(AuthService())
            .environmentObject(NotificationScheduleStore())
    }
}
