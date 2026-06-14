import SwiftUI

struct PastSessionsView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        ScrollView {
            if sessionStore.sessions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(sessionStore.sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRowView(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Past Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await sessionStore.loadSessionsFromSupabase()
        }
        .refreshable {
            await sessionStore.loadSessionsFromSupabase()
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.primaryGradient)

            VStack(spacing: AppTheme.Spacing.small) {
                Text("No sessions yet")
                    .font(.title3.weight(.semibold))

                Text("Completed check-ins will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 360)
    }
}

#Preview {
    NavigationStack {
        PastSessionsView()
            .environmentObject(AuthService())
            .environmentObject(SessionStore())
            .environmentObject(StreakStore())
            .environmentObject(AppearanceStore())
    }
}
