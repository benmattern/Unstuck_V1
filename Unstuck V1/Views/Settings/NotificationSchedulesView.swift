import Supabase
import SwiftUI

private enum NotificationScheduleDateHelpers {
    static var defaultDailyTime: Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static func timeString(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d:00", components.hour ?? 0, components.minute ?? 0)
    }

    static func date(fromScheduledTime scheduledTime: String?) -> Date {
        guard let scheduledTime else {
            return defaultDailyTime
        }

        let parts = scheduledTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else {
            return defaultDailyTime
        }

        var components = DateComponents()
        components.hour = parts[0]
        components.minute = parts[1]
        return Calendar.current.date(from: components) ?? defaultDailyTime
    }

    static func displayTime(from scheduledTime: String?) -> String {
        date(fromScheduledTime: scheduledTime).formatted(date: .omitted, time: .shortened)
    }
}

struct NotificationSchedulesView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var notificationScheduleStore: NotificationScheduleStore
    @State private var title = ""
    @State private var scheduleType: NotificationScheduleType = .daily
    @State private var formType: NotificationScheduleFormType = .shortCheckIn
    @State private var oneTimeDate = Date().addingTimeInterval(3600)
    @State private var dailyTime = NotificationScheduleDateHelpers.defaultDailyTime
    @State private var isEnabled = true
    @State private var editingSchedule: NotificationSchedule?
    @State private var statusMessage: String?

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
        .sheet(item: $editingSchedule) { schedule in
            EditNotificationScheduleView(schedule: schedule) { message in
                statusMessage = message
            }
            .environmentObject(notificationScheduleStore)
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
                Button {
                    editingSchedule = schedule
                } label: {
                    HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            Text(schedule.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(schedule.formType.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(scheduleDescription(schedule))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Toggle(
                    "Enabled",
                    isOn: Binding(
                        get: { schedule.isEnabled },
                        set: { newValue in
                            updateSchedule(schedule, isEnabled: newValue)
                        }
                    )
                )
                .font(.subheadline.weight(.semibold))

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
        let scheduledTime = scheduleType == .daily ? NotificationScheduleDateHelpers.timeString(from: dailyTime) : nil

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
            return "Daily: \(NotificationScheduleDateHelpers.displayTime(from: schedule.scheduledTime))"
        }
    }

}

private struct EditNotificationScheduleView: View {
    let schedule: NotificationSchedule
    let onStatus: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationScheduleStore: NotificationScheduleStore
    @State private var title: String
    @State private var scheduleType: NotificationScheduleType
    @State private var formType: NotificationScheduleFormType
    @State private var oneTimeDate: Date
    @State private var dailyTime: Date
    @State private var isEnabled: Bool

    init(schedule: NotificationSchedule, onStatus: @escaping (String) -> Void) {
        self.schedule = schedule
        self.onStatus = onStatus
        _title = State(initialValue: schedule.title)
        _scheduleType = State(initialValue: schedule.scheduleType)
        _formType = State(initialValue: schedule.formType)
        _oneTimeDate = State(initialValue: schedule.scheduledAt ?? Date().addingTimeInterval(3600))
        _dailyTime = State(initialValue: NotificationScheduleDateHelpers.date(fromScheduledTime: schedule.scheduledTime))
        _isEnabled = State(initialValue: schedule.isEnabled)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    SectionHeader("Edit Reminder", subtitle: "Update when this reminder appears.")
                    editCard
                }
                .padding(AppTheme.Spacing.large)
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var editCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
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
                    saveChanges()
                } label: {
                    PrimaryButton(notificationScheduleStore.isLoading ? "Saving..." : "Save Changes", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(notificationScheduleStore.isLoading)
            }
        }
    }

    private func saveChanges() {
        let scheduleTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Unstuck Reminder"
            : title.trimmingCharacters(in: .whitespacesAndNewlines)
        let scheduledAt = scheduleType == .oneTime ? oneTimeDate : nil
        let scheduledTime = scheduleType == .daily
            ? NotificationScheduleDateHelpers.timeString(from: dailyTime)
            : nil

        Task {
            await notificationScheduleStore.updateSchedule(
                schedule,
                title: scheduleTitle,
                isEnabled: isEnabled,
                scheduleType: scheduleType,
                scheduledAt: scheduledAt,
                scheduledTime: scheduledTime,
                formType: formType
            )

            await MainActor.run {
                onStatus(notificationScheduleStore.errorMessage ?? "Notification schedule updated.")
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSchedulesView()
            .environmentObject(AuthService(restoreSessionOnInit: false))
            .environmentObject(NotificationScheduleStore())
    }
}
