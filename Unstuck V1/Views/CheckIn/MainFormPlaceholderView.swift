import SwiftUI

struct MainFormPlaceholderView: View {
    var body: some View {
        PlaceholderScreenView(title: "Main Form")
    }
}

#Preview {
    NavigationStack {
        MainFormPlaceholderView()
    }
}
