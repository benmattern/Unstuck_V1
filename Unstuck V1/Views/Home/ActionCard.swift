import SwiftUI

struct ActionCard: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var userStatsStore: UserStatsStore

    private var hasCompletedToday: Bool {
        userStatsStore.completedToday || sessionStore.sessions.contains {
            Calendar.current.isDateInToday($0.completedAt)
        }
    }

    private var currentStreakText: String {
        let currentStreak = userStatsStore.currentStreak
        return "\(currentStreak) \(currentStreak == 1 ? "day" : "days")"
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                SectionHeader("Today's Focus")

                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(hasCompletedToday ? "Already checked in today" : "Ready to check in?")
                        .font(.title3.weight(.semibold))

                    Text(hasCompletedToday ? "Current streak: \(currentStreakText)" : "You have not completed a session today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: AppTheme.Spacing.medium) {
                    NavigationLink {
                        CheckInFlowView(form: SampleForms.shortCheckIn)
                    } label: {
                        PrimaryButton(
                            hasCompletedToday ? "Start Another Check-In" : "Start Short Check-In",
                            systemImage: "arrow.up.circle.fill"
                        )
                    }

                    NavigationLink {
                        if hasCompletedToday {
                            InsightsView()
                        } else {
                            CheckInFlowView(form: SampleForms.mainForm)
                        }
                    } label: {
                        SecondaryButton(
                            hasCompletedToday ? "View Insights" : "Start Main Form",
                            systemImage: hasCompletedToday ? "chart.line.uptrend.xyaxis" : "doc.text"
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActionCard()
            .environmentObject(AuthService())
            .environmentObject(SessionStore())
            .environmentObject(StreakStore())
            .environmentObject(UserStatsStore())
            .environmentObject(AppearanceStore())
            .padding()
    }
    .background(AppTheme.screenBackground)
}
