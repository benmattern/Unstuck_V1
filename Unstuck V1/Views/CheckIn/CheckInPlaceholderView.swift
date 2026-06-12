import SwiftUI

struct CheckInPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Short Check-In")
    }
}

#Preview {
    NavigationStack {
        CheckInPlaceholderView()
    }
}
