import Combine
import Foundation
import Supabase

@MainActor
final class ProfileStore: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadProfile(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: PostgrestResponse<Profile> = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()

            profile = response.value
            errorMessage = nil
        } catch {
            profile = nil
            errorMessage = "Unable to load profile."
            print("Supabase profile load failed: \(error)")
        }
    }

    func updateDisplayName(userId: UUID, displayName: String) async {
        isLoading = true
        defer { isLoading = false }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = ProfileDisplayNameUpdate(
            display_name: trimmedName.isEmpty ? nil : trimmedName,
            updated_at: Date()
        )

        do {
            let response: PostgrestResponse<Profile> = try await supabase
                .from("profiles")
                .update(payload)
                .eq("id", value: userId.uuidString)
                .select()
                .single()
                .execute()

            profile = response.value
            errorMessage = nil
        } catch {
            errorMessage = "Unable to save display name."
            print("Supabase profile update failed: \(error)")
        }
    }

    func updatePreferredTheme(userId: UUID, appearance: AppAppearance) async {
        isLoading = true
        defer { isLoading = false }

        let payload = ProfileThemeUpdate(
            preferred_theme: appearance.rawValue,
            updated_at: Date()
        )

        do {
            let response: PostgrestResponse<Profile> = try await supabase
                .from("profiles")
                .update(payload)
                .eq("id", value: userId.uuidString)
                .select()
                .single()
                .execute()

            profile = response.value
            errorMessage = nil
        } catch {
            errorMessage = "Unable to save appearance."
            print("Supabase profile theme update failed: \(error)")
        }
    }

    func clear() {
        profile = nil
        isLoading = false
        errorMessage = nil
    }
}

private struct ProfileDisplayNameUpdate: Encodable {
    let display_name: String?
    let updated_at: Date
}

private struct ProfileThemeUpdate: Encodable {
    let preferred_theme: String
    let updated_at: Date
}
