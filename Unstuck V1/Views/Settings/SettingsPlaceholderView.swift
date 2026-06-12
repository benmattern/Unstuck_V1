import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsPlaceholderView()
    }
}
