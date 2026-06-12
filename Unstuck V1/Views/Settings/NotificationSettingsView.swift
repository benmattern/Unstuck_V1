import SwiftUI

struct NotificationSettingsView: View {
    @State private var isDailyReminderEnabled = false
    @State private var reminderTime = Self.defaultReminderTime
    @State private var statusMessage: String?

    private static var defaultReminderTime: Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                SectionHeader("Daily Reminder", subtitle: "Schedule one local reminder for a check-in.")

                settingsCard
                actionButtons

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
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Toggle("Enable Daily Reminder", isOn: $isDailyReminderEnabled)
                    .font(.headline)

                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Button {
                requestPermission()
            } label: {
                SecondaryButton("Request Notification Permission", systemImage: "bell.badge")
            }
            .buttonStyle(.plain)

            Button {
                saveReminder()
            } label: {
                PrimaryButton("Save Reminder", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.plain)

            Button {
                cancelReminder()
            } label: {
                SecondaryButton("Cancel Reminder", systemImage: "bell.slash")
            }
            .buttonStyle(.plain)
        }
    }

    private func requestPermission() {
        Task {
            do {
                let granted = try await NotificationManager.requestPermission()
                await MainActor.run {
                    statusMessage = granted ? "Notification permission granted." : "Notification permission was not granted."
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Unable to request notification permission."
                }
            }
        }
    }

    private func saveReminder() {
        guard isDailyReminderEnabled else {
            NotificationManager.cancelPendingUnstuckNotifications()
            statusMessage = "Daily reminder is off."
            return
        }

        Task {
            do {
                _ = try await NotificationManager.requestPermission()
                try await NotificationManager.scheduleDailyReminder(at: reminderTime)
                await MainActor.run {
                    statusMessage = "Daily reminder saved."
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Unable to save daily reminder."
                }
            }
        }
    }

    private func cancelReminder() {
        NotificationManager.cancelPendingUnstuckNotifications()
        isDailyReminderEnabled = false
        statusMessage = "Daily reminder canceled."
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
