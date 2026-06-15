import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var userStatsStore: UserStatsStore

    private var currentStreakText: String {
        let currentStreak = userStatsStore.currentStreak
        return "\(currentStreak) \(currentStreak == 1 ? "day" : "days")"
    }

    private var completedTodayText: String {
        userStatsStore.completedToday ? "Yes" : "No"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    header
                    todaySection
                    reviewSection
                    manageSection
                }
                .padding(AppTheme.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppTheme.screenBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.primaryGradient)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Unstuck")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                Text("A calm tool for getting moving again")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, AppTheme.Spacing.large)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Today")
            ActionCard()
            progressCard
        }
    }

    private var progressCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                SectionHeader("Progress")

                HStack(spacing: AppTheme.Spacing.large) {
                    progressValue(title: "Current Streak", value: currentStreakText)
                    progressValue(title: "Completed Today", value: completedTodayText)
                }
            }
        }
    }

    private func progressValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.primaryGradient)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewSection: some View {
        navigationSection(title: "Review") {
            NavigationLink {
                PastSessionsView()
            } label: {
                SecondaryButton("Past Sessions", systemImage: "clock")
            }

            NavigationLink {
                InsightsView()
            } label: {
                SecondaryButton("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }

    private var manageSection: some View {
        navigationSection(title: "Manage") {
            NavigationLink {
                NotificationSchedulesView()
            } label: {
                SecondaryButton("Reminders", systemImage: "bell.badge")
            }

            NavigationLink {
                SettingsView()
            } label: {
                SecondaryButton("Settings", systemImage: "gearshape")
            }
        }
    }

    private func navigationSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title)

            AppCard {
                VStack(spacing: AppTheme.Spacing.medium) {
                    content()
                }
            }
        }
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(AppTheme.primaryGradient.opacity(configuration.isPressed ? 0.82 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(AppTheme.cardBackground.opacity(configuration.isPressed ? 0.72 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService(restoreSessionOnInit: false))
        .environmentObject(SessionStore())
        .environmentObject(StreakStore())
        .environmentObject(UserStatsStore())
        .environmentObject(AppearanceStore())
        .environmentObject(NotificationScheduleStore())
}
