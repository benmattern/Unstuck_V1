import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var displayName: String?
    var preferredTheme: String
    var onboardingCompleted: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case preferredTheme = "preferred_theme"
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
