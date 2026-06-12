import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    header
                    signInCard
                }
                .padding(AppTheme.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppTheme.screenBackground)
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

                Text("Sign in to sync sessions with Supabase.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, AppTheme.Spacing.large)
    }

    private var signInCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                SectionHeader("Sign In", subtitle: "Use one of the Supabase test users.")

                VStack(spacing: AppTheme.Spacing.medium) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .fieldStyle()

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .fieldStyle()
                }

                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button {
                    signIn()
                } label: {
                    PrimaryButton(authService.isLoading ? "Signing In..." : "Sign In")
                }
                .buttonStyle(.plain)
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                .opacity(authService.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
            }
        }
    }

    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
        }
    }
}

private extension View {
    func fieldStyle() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(AppTheme.Spacing.medium)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
        .environmentObject(SessionStore())
        .environmentObject(StreakStore())
        .environmentObject(AppearanceStore())
}
