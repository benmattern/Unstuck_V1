import SwiftUI

struct PastSessionsPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Past Sessions")
    }
}

#Preview {
    NavigationStack {
        PastSessionsPlaceholderView()
    }
}
