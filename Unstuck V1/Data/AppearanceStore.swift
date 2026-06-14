import Combine
import Foundation

final class AppearanceStore: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet {
            persistAppearance()
        }
    }

    private let userDefaults: UserDefaults
    private let appearanceKey = "unstuck.appearance"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.appearance = Self.loadAppearance(from: userDefaults, key: appearanceKey)
    }

    func applyProfileTheme(_ preferredTheme: String) {
        appearance = AppAppearance(rawValue: preferredTheme) ?? .system
    }

    func resetToSystem() {
        appearance = .system
    }

    private func persistAppearance() {
        userDefaults.set(appearance.rawValue, forKey: appearanceKey)
    }

    private static func loadAppearance(from userDefaults: UserDefaults, key: String) -> AppAppearance {
        guard let rawValue = userDefaults.string(forKey: key),
              let appearance = AppAppearance(rawValue: rawValue) else {
            return .system
        }

        return appearance
    }
}
