import Combine
import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var errorMessage: String?

    init() {
        Task {
            await restoreSession()
        }
    }

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            errorMessage = nil
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            currentUser = session.user
            isAuthenticated = true
            errorMessage = nil
        } catch {
            currentUser = nil
            isAuthenticated = false
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            print("Supabase sign in failed: \(error)")
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
        } catch {
            errorMessage = "Unable to sign out."
        }

        currentUser = nil
        isAuthenticated = false
    }
}
