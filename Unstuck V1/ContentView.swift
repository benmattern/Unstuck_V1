import SwiftUI

enum AppTheme {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 20
        static let button: CGFloat = 16
    }

    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.18, green: 0.42, blue: 0.90),
            Color(red: 0.48, green: 0.28, blue: 0.86)  
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let screenBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func unstuckCardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

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
                    ActionCard()
                    progressCard
                    actionButtons
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

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            NavigationLink {
                CheckInFlowView(form: SampleForms.shortCheckIn)
            } label: {
                PrimaryButton("Start Short Check-In", systemImage: "arrow.up.circle.fill")
            }

            NavigationLink {
                CheckInFlowView(form: SampleForms.mainForm)
            } label: {
                SecondaryButton("Start Main Form", systemImage: "doc.text")
            }

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

            NavigationLink {
                SettingsView()
            } label: {
                SecondaryButton("Settings", systemImage: "gearshape")
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

struct CheckInPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Short Check-In")
    }
}

struct MainFormPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Main Form")
    }
}

struct PastSessionsPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Past Sessions")
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Settings")
    }
}

struct PlaceholderScreenView: View {
    let title: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppTheme.primaryGradient)

            Text(title)
                .font(.title2.weight(.semibold))

            Text("This screen will be built in a later step.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.screenBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(SessionStore())
        .environmentObject(StreakStore())
        .environmentObject(UserStatsStore())
        .environmentObject(AppearanceStore())
}
