import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    private var totalSessions: Int {
        sessionStore.sessions.count
    }

    private var shortCheckInsCompleted: Int {
        sessionStore.sessions.filter { $0.formId == "short_check_in" }.count
    }

    private var mainFormsCompleted: Int {
        sessionStore.sessions.filter { $0.formId == "main_form" }.count
    }

    private var mostRecentSessionText: String {
        guard let mostRecentSession = sessionStore.sessions.first else {
            return "None"
        }

        return mostRecentSession.completedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var mostCommonBlockerText: String {
        let blockerCounts = sessionStore.sessions
            .flatMap(\.answers)
            .filter { $0.questionId == "main_blocker" || $0.questionId == "biggest_obstacle" }
            .reduce(into: [String: Int]()) { counts, answer in
                let value = answer.value.trimmingCharacters(in: .whitespacesAndNewlines)

                if !value.isEmpty {
                    counts[value, default: 0] += 1
                }
            }

        return blockerCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }

                return lhs.value > rhs.value
            }
            .first?
            .key ?? "Not enough data"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                if totalSessions == 0 {
                    emptyState
                } else {
                    overviewSection
                    patternsSection
                    formsSection
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        AppCard {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryGradient)

                Text("Complete more sessions to unlock insights.")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 260)
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Overview")

            AppCard {
                VStack(spacing: AppTheme.Spacing.medium) {
                    metricRow(title: "Total Sessions", value: "\(totalSessions)")
                    Divider()
                    metricRow(title: "Most Recent Session", value: mostRecentSessionText)
                }
            }
        }
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Patterns")

            AppCard {
                metricRow(title: "Most Common Blocker", value: mostCommonBlockerText)
            }
        }
    }

    private var formsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Forms")

            AppCard {
                VStack(spacing: AppTheme.Spacing.medium) {
                    metricRow(title: "Short Check-Ins", value: "\(shortCheckInsCompleted)")
                    Divider()
                    metricRow(title: "Main Forms", value: "\(mainFormsCompleted)")
                }
            }
        }
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.medium) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView()
            .environmentObject(AuthService(restoreSessionOnInit: false))
            .environmentObject(SessionStore())
            .environmentObject(StreakStore())
            .environmentObject(AppearanceStore())
    }
}
