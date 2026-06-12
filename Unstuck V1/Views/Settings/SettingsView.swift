import Supabase
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var streakStore: StreakStore
    @EnvironmentObject private var appearanceStore: AppearanceStore
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
                streakStore.reset()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your current streak and completed-today status.")
        }
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
                        Text("Signed in as")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(authService.currentUser?.email ?? "Unknown user")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                Picker("Appearance", selection: $appearanceStore.appearance) {
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
            SectionHeader("Notifications", subtitle: "Set a simple daily reminder.")

            NavigationLink {
                NotificationSettingsView()
            } label: {
                SecondaryButton("Daily Reminder", systemImage: "bell")
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
            .environmentObject(AppearanceStore())
    }
}
