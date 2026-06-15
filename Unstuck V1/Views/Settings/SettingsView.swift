import Supabase
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var streakStore: StreakStore
    @EnvironmentObject private var appearanceStore: AppearanceStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var userStatsStore: UserStatsStore
    @State private var displayNameDraft = ""
    @State private var showingDeleteSessionsConfirmation = false
    @State private var showingResetStreakConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                appInfoCard
                accountSection
                appearanceSection
                notificationsSection
                localDataSection
            }
            .padding(AppTheme.Spacing.large)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: authService.currentUser?.id) {
            guard let userId = authService.currentUser?.id else {
                profileStore.clear()
                return
            }

            await profileStore.loadProfile(userId: userId)
            displayNameDraft = profileStore.profile?.displayName ?? ""

            if let preferredTheme = profileStore.profile?.preferredTheme {
                appearanceStore.applyProfileTheme(preferredTheme)
            }
        }
        .onChange(of: profileStore.profile?.displayName) { _, displayName in
            displayNameDraft = displayName ?? ""
        }
        .alert("Delete all sessions?", isPresented: $showingDeleteSessionsConfirmation) {
            Button("Delete All Sessions", role: .destructive) {
                sessionStore.deleteAllSessions()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes saved check-ins from this device.")
        }
        .alert("Reset streak?", isPresented: $showingResetStreakConfirmation) {
            Button("Reset Streak", role: .destructive) {
                guard let userId = authService.currentUser?.id else {
                    userStatsStore.clear()
                    streakStore.reset()
                    return
                }

                Task {
                    await userStatsStore.resetStats(userId: userId)
                    streakStore.reset()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your current streak and completed-today status.")
        }
    }

    private var appearanceSelection: Binding<AppAppearance> {
        Binding(
            get: { appearanceStore.appearance },
            set: { newAppearance in
                appearanceStore.appearance = newAppearance

                guard let userId = authService.currentUser?.id else {
                    return
                }

                Task {
                    await profileStore.updatePreferredTheme(
                        userId: userId,
                        appearance: newAppearance
                    )
                }
            }
        )
    }

    private var appInfoCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Unstuck")
                    .font(.title2.weight(.semibold))

                Text("V1 Local Build")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var localDataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Local Data", subtitle: "Manage information stored on this device.")

            AppCard {
                VStack(spacing: AppTheme.Spacing.small) {
                    Button {
                        showingDeleteSessionsConfirmation = true
                    } label: {
                        SecondaryButton("Delete All Sessions", systemImage: "trash")
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingResetStreakConfirmation = true
                    } label: {
                        SecondaryButton("Reset Streak", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Account", subtitle: "Supabase authentication for this device.")

            AppCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(authService.currentUser?.email ?? "Unknown user")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Display Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Display name", text: $displayNameDraft)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(AppTheme.Spacing.medium)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
                    }

                    if let errorMessage = profileStore.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        guard let userId = authService.currentUser?.id else {
                            return
                        }

                        Task {
                            await profileStore.updateDisplayName(
                                userId: userId,
                                displayName: displayNameDraft
                            )
                        }
                    } label: {
                        PrimaryButton(profileStore.isLoading ? "Saving..." : "Save Display Name", systemImage: "person.crop.circle")
                    }
                    .buttonStyle(.plain)
                    .disabled(profileStore.isLoading)

                    Button {
                        Task {
                            await authService.signOut()
                        }
                    } label: {
                        SecondaryButton("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Appearance", subtitle: "Choose how Unstuck follows your device display.")

            AppCard {
                Picker("Appearance", selection: appearanceSelection) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.displayName)
                            .tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Notifications", subtitle: "Manage Supabase-backed reminders.")

            NavigationLink {
                NotificationSchedulesView()
            } label: {
                SecondaryButton("Notification Schedules", systemImage: "bell.badge")
            }
            .buttonStyle(.plain)

            NavigationLink {
                NotificationSettingsView()
            } label: {
                SecondaryButton("Legacy Daily Reminder", systemImage: "bell")
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthService())
            .environmentObject(SessionStore())
            .environmentObject(StreakStore())
            .environmentObject(UserStatsStore())
            .environmentObject(AppearanceStore())
            .environmentObject(ProfileStore())
            .environmentObject(NotificationScheduleStore())
    }
}
